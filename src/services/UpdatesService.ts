import EmailTemplateService from "./EmailTemplateService";
import DynamoService from "./DynamoService";
import Update from "../models/Update";

export default class UpdatesService {
  private dynamoService: DynamoService;
  private emailTemplateService: EmailTemplateService;

  constructor(
    dynamoService: DynamoService,
    emailTemplateService: EmailTemplateService
  ) {
    this.dynamoService = dynamoService;
    this.emailTemplateService = emailTemplateService;
  }

  public async processUpdate(update: Update) {
    try {
      await this.emailTemplateService.sendUpdate(update);
      const results = await this.dynamoService.recordUpdate(update);
    } catch (err) {
      console.log("error in processing update");
      console.log(err);
      throw err;
    }
  }

  public async getUpdates(email: string) {
    let results;
    try {
      results = await this.dynamoService.getUpdates(email);
    } catch (err) {
      console.log("error in fetching updates");
      console.log(err);
      throw err;
    }
    return results;
  }
}
