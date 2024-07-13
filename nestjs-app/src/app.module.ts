import { Module } from '@nestjs/common';
import { CouchDbModule } from './couchdb/couchdb.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [CouchDbModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
