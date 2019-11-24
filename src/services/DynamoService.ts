import { DocumentClient } from "aws-sdk/lib/dynamodb/document_client";
import Update from "../models/Update";

export default class DynamoService {
  private readonly updatesHistoryTableName: string;
  private documentClient: DocumentClient;

  constructor(
    documentClient: DocumentClient,
    updatesHistoryTableName: string = process.env.UPDATES_HISTORY_TABLE_NAME
  ) {
    this.documentClient = documentClient;
    this.updatesHistoryTableName = updatesHistoryTableName;
  }

  public async recordUpdate(update: Update) {
    let results;

    try {
      results = await this.documentClient
        .put({
          TableName: this.updatesHistoryTableName,
          Item: {
            recipientemail: update.recipientEmail,
            timestamp: new Date().toISOString(),
            message: update.message
          }
        })
        .promise();
    } catch (err) {
      console.log("something went wrong when persisting update into dynamo");
      console.log(err);
      throw err;
    }
  }

  public async getUpdates(email: string) {
    let results;

    try {
      results = await this.documentClient
        .query({
          KeyConditionExpression: `recipientemail = :email`,
          ExpressionAttributeValues: {
            ":email": email
          },
          TableName: this.updatesHistoryTableName
        })
        .promise();
    } catch (err) {
      console.log("error in querying");
      console.log(err);
    }

    return results;
  }
}
