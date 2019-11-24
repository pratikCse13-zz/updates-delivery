import { ApplicationError } from "./ApplicationError";

export class UnauthorizedError extends ApplicationError {
  public static readonly statusCode = 401;

  constructor(message: string, details?: any) {
    super(UnauthorizedError.statusCode, message, details);
  }
}
