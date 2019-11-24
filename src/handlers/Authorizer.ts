import { AuthenticationService } from "../services/AuthenticationService";
import { CustomAuthorizerEvent } from "aws-lambda";
import Resources from "../models/Resources";
import setup from "../services/SetupService";

export const auth = async (
  event: CustomAuthorizerEvent,
  authenticationService: AuthenticationService
) => {
  return authenticationService.authenticate(
    event.methodArn,
    event.authorizationToken
  );
};

const resources: Resources = setup();

/* istanbul ignore next */
export const handler = async (event: CustomAuthorizerEvent) => {
  try {
    return await auth(event, await resources.authenticationService);
  } catch (err) {
    console.error("Error in the authorizer lambda", {}, err);
    throw err;
  }
};
