import DynamoDB from "aws-sdk/clients/dynamodb";
import SES from "aws-sdk/clients/ses";
import DynamoService from "../services/DynamoService";
import EmailTemplateService from "../services/EmailTemplateService";
import EmailService from "../services/EmailService";
import UpdatesService from "../services/UpdatesService";
import Resources from "../models/Resources";
import { AuthenticationService } from "./AuthenticationService";
import { JwtService } from "./JwtService";
import jwksClientFactory from "jwks-rsa";

export default function setup(): Resources {
  const documentClient = new DynamoDB.DocumentClient();
  const emailService = new EmailService(
    new SES({
      apiVersion: "2010-12-01",
      region: "eu-west-1"
    })
  );
  const emailTemplateService = new EmailTemplateService(
    emailService,
    process.env.EMAIL_SENDER_ADDRESS
  );
  const dynamoService = new DynamoService(documentClient);
  const updatesService = new UpdatesService(
    dynamoService,
    emailTemplateService
  );
  const authenticationService = new AuthenticationService(
    {
      tokenIssuer: process.env.TOKEN_ISSUER,
      audience: process.env.AUDIENCE
    },
    new JwtService(
      jwksClientFactory({
        cache: true,
        jwksRequestsPerMinute: 100, // Default value
        jwksUri: process.env.JWKS_URI,
        rateLimit: true
      })
    ),
    ["dummy@gmail.com"],
    process.env.TEST_CLIENT_ID
  );

  return {
    documentClient,
    emailTemplateService,
    dynamoService,
    updatesService,
    authenticationService
  };
}
