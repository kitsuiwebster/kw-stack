import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { CouchDbController } from './couchdb.controller';
import { CouchDbService } from './couchdb.service';

@Module({
  imports: [HttpModule],
  controllers: [CouchDbController],
  providers: [CouchDbService],
})
export class CouchDbModule {}
