import EmailTemplateService from "../services/EmailTemplateService";
import DynamoService from "../services/DynamoService";
import DynamoDB from "aws-sdk/clients/dynamodb";
import UpdatesService from "../services/UpdatesService";
import { AuthenticationService } from "../services/AuthenticationService";

export default interface Resources {
  documentClient: DynamoDB.DocumentClient;
  emailTemplateService: EmailTemplateService;
  dynamoService: DynamoService;
  updatesService: UpdatesService;
  authenticationService: AuthenticationService;
}
