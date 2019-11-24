local accountData = {
  dev: {
    accountName: 'DAZN-AR-DEV',
    account: 'accountId'
  }
};

local roleToAssume(env) = 'arn:aws:iam::%(account)s:role/role-name' % { account: accountData[env].account };

local getProfileId(env) = accountData[env].account;

local activeRegion = 'eu-central-1';

local variables = {
  repo: '${DRONE_REPO}',
  version: '${DRONE_COMMIT_SHA:0:10}',
  build_number: '${DRONE_BUILD_NUMBER:0:10}'
};

local whenCommitToNonMaster(step) = step {
  when: {
    event: 'push',
    branch: {
      exclude: 'master',
    },
  },
};

local whenCommitToMaster(step) = step {
  when: {
    event: 'push',
    branch: 'master',
  },
};

// Manual deploy to <env>
// drone deploy <THIS_REPO> <BUILD_NO> <env>
local whenCliDeployTo(environment) = function(step) step {
  when: {
    event: 'deployment',
    environment: environment,
  },
};

local compile_typescript = {
  name:: 'compile-code',
  image: 'node:8.10-alpine',
  commands: [
    'npm i',
    'npm run build',
  ],
};

local plan_message_delivery_service(env, region) = {
  name:: '%(env)s-plan-message-delivery-service-%(region)s' % { env: env, region: region },
  image: 'jmccann/drone-terraform:5.3-0.11.14',
  root_dir: 'terraform/message-delivery',
  actions: [
    'validate',
    'plan',
  ],
  init_options: {
    'backend-config': [
      'config/%(profileId)s_%(env)s/%(region)s/config.remote' % { profileId: getProfileId(env), env: env, region: region },
    ],
  },
  var_files: [
    'config/%(profileId)s_%(env)s/%(region)s/config.remote' % { profileId: getProfileId(env), env: env, region: region },
    'config/%(profileId)s_%(env)s/%(region)s/terraform.tfvars' % { profileId: getProfileId(env), env: env, region: region },
  ],
  vars: variables,
  role_arn_to_assume: roleToAssume(env),
  environment: {
    TF_DATA_DIR: '.terraform_%(env)s_%(region)s' % { env: env, region: region },
  },
};

local deploy_message_delivery_service(env, region) = {
  name:: '%(env)s-deploy-message-delivery-service-%(region)s' % { env: env, region: region },
  image: 'jmccann/drone-terraform:5.3-0.11.14',
  root_dir: 'terraform/message-delivery',
  init_options: {
    'backend-config': [
      'config/%(profileId)s_%(env)s/%(region)s/config.remote' % { profileId: getProfileId(env), env: env, region: region },
    ],
  },
  var_files: [
    'config/%(profileId)s_%(env)s/%(region)s/config.remote' % { profileId: getProfileId(env), env: env, region: region },
    'config/%(profileId)s_%(env)s/%(region)s/terraform.tfvars' % { profileId: getProfileId(env), env: env, region: region },
  ],
  vars: variables,
  role_arn_to_assume: roleToAssume(env),
  environment: {
    TF_DATA_DIR: '.terraform_%(env)s_%(region)s' % { env: env, region: region },
  },
};

local packageArtefact(env) = {
  name:: '%(env)s-package-artefact' % { env: env },
  image: 'kramos/alpine-zip',
  commands:
    'zip -r code.zip ./dist ./node_modules package.json',
};

local deployArtefact(region, env) = {
  name:: '%(env)s-deploy-artefact-%(region)s' % { region: region, env: env },
  image: 'nzad/drone-lambda-artefact-pusher',
  bucket_prefix: 'lambda-artefacts',
  file: 'code.zip',
  version: '${DRONE_COMMIT_SHA:0:10}',
  regions: region,
};

local commitToNonMasterSteps = std.map(whenCommitToNonMaster, [
  compile_typescript,
  plan_message_delivery_service('dev', activeRegion)
]);

local commitToMasterSteps = std.map(whenCommitToMaster, [
  compile_typescript,
  packageArtefact('dev'),
  deployArtefact(activeRegion, 'dev'),
  plan_message_delivery_service('dev', activeRegion),
  deploy_message_delivery_service('dev', activeRegion)  
]);

local cliDeployStep(env) = std.map(whenCliDeployTo(env), [
  compile_typescript,
  packageArtefact('dev'),
  deployArtefact(activeRegion, 'dev'),
  plan_message_delivery_service(env, activeRegion),
  deploy_message_delivery_service(env, activeRegion)
]);

// All the pipelines
local pipelineSteps = std.flattenArrays([
  commitToNonMasterSteps,
  commitToMasterSteps,
  cliDeployStep('dev')
]);

// Drone 0.8 expects the 'pipeline' field to be an object of steps, the order is important but jsonnet will sort the keys (i.e. step name). So we are adding index number to all step names to preserve the order. This can be removed when we migrate to Drone 1.0 which takes the steps as an array, which guarantees the order.
// e.g. 'unitTest' => '001_unitTest'
local addIndexToObject(index, obj) = obj { name: std.format('%03d_%s', [index, obj.name]) };
local arrayToObjectWithName(accObj, newObj) = accObj { [newObj.name]: newObj };

local convertStepsToDronePipelineObjectWithIndexedName(steps) =
  std.foldl(arrayToObjectWithName, std.mapWithIndex(addIndexToObject, steps), {});

// The actual output
{ pipeline: convertStepsToDronePipelineObjectWithIndexedName(pipelineSteps) }
