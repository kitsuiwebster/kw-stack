import { Injectable } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';

@Injectable()
export class CouchDbService {
  constructor(private readonly httpService: HttpService) {}

  async getCouchDbInfo(): Promise<any> {
    return 'Hello CouchDB!';
  }
}
