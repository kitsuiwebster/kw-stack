import { Controller, Get } from '@nestjs/common';
import { CouchDbService } from './couchdb.service';

@Controller('couchdb')
export class CouchDbController {
  constructor(private readonly couchDbService: CouchDbService) {}

  @Get()
  async getCouchDbInfo(): Promise<any> {
    return this.couchDbService.getCouchDbInfo();
  }
}
