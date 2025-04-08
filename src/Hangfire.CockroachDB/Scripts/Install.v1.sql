-- Create the 'hangfire' schema if it doesn't exist.
CREATE SCHEMA IF NOT EXISTS "hangfire";

SET search_path = 'hangfire';

--
-- Table structure for table `Schema`
--
CREATE TABLE IF NOT EXISTS "schema"
(
    "version" INT NOT NULL,
    PRIMARY KEY ("version")
);

-- Initialize the schema version if it's a fresh install.
INSERT INTO "schema" ("version")
SELECT 0
    WHERE NOT EXISTS (SELECT 0 FROM "schema");


--
-- Table structure for table `Counter`
--
CREATE TABLE IF NOT EXISTS "counter"
(
    "id"          BIGSERIAL                   NOT NULL,
    "key"         TEXT                        NOT NULL,
    "value"       bigint                      NOT NULL,
    "expireat"    TIMESTAMP WITH TIME ZONE    NULL,
    PRIMARY KEY ("id")
);

CREATE INDEX "ix_hangfire_counter_expireat" ON "counter" ("expireat");
CREATE INDEX "ix_hangfire_counter_key" ON "counter" ("key");


--
-- Table structure for table `Hash`
--
CREATE TABLE IF NOT EXISTS "hash"
(
    "id"          BIGSERIAL                 NOT NULL,
    "key"         TEXT                      NOT NULL,
    "field"       TEXT                      NOT NULL,
    "value"       TEXT                      NULL,
    "expireat"    TIMESTAMP WITH TIME ZONE  NULL,
    "updatecount" INTEGER                   NOT NULL DEFAULT 0,
    PRIMARY KEY ("id"),
    UNIQUE ("key", "field")
);

CREATE INDEX "ix_hangfire_hash_expireat" ON "hash" ("expireat");


--
-- Table structure for table `Job`
--
CREATE TABLE IF NOT EXISTS "job"
(
    "id"             BIGSERIAL                     NOT NULL,
    "stateid"        BIGINT                        NULL,
    "statename"      TEXT                          NULL,
    "invocationdata" jsonb                         NOT NULL,
    "arguments"      jsonb                         NOT NULL,
    "createdat"      TIMESTAMP WITH TIME ZONE      NOT NULL,
    "expireat"       TIMESTAMP WITH TIME ZONE      NULL,
    "updatecount"    INTEGER                       NOT NULL DEFAULT 0,
    PRIMARY KEY ("id")
);

CREATE INDEX "ix_hangfire_job_statename" ON "job" ("statename");
CREATE INDEX "ix_hangfire_job_expireat" ON "job" ("expireat");
-- CockroachDB does not support the PostgreSQL INCLUDE clause. Instead, it supports a similar mechanism via the STORING clause.
-- Therefore, this index is changed from the original.
-- CREATE INDEX "ix_hangfire_job_statename_is_not_null" ON "job" USING btree("statename") INCLUDE ("id") WHERE "statename" IS NOT NULL;
CREATE INDEX "ix_hangfire_job_statename_is_not_null" ON "job" ("statename") WHERE "statename" IS NOT NULL;

--
-- Table structure for table `State`
--
CREATE TABLE IF NOT EXISTS "state"
(
    "id"          BIGSERIAL                 NOT NULL,
    "jobid"       BIGINT                    NOT NULL,
    "name"        TEXT                      NOT NULL,
    "reason"      TEXT                      NULL,
    "createdat"   TIMESTAMP WITH TIME ZONE  NOT NULL,
    "data"        jsonb                     NULL,
    "updatecount" INTEGER                   NOT NULL DEFAULT 0,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("jobid") REFERENCES "job" ("id") ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX "ix_hangfire_state_jobid" ON "state" ("jobid");


--
-- Table structure for table `JobQueue`
--
CREATE TABLE IF NOT EXISTS "jobqueue"
(
    "id"          BIGSERIAL                 NOT NULL,
    "jobid"       BIGINT                    NOT NULL,
    "queue"       TEXT                      NOT NULL,
    "fetchedat"   TIMESTAMP WITH TIME ZONE  NULL,
    "updatecount" INTEGER                   NOT NULL DEFAULT 0,
    PRIMARY KEY ("id")
);

-- CockroachDB does not currently support ordering null first with 'nulls first'. The default when sorting by 'asc' is to order null first. 'desc' order null last
-- Therefore, this index is changed from the original.
-- See: https://www.cockroachlabs.com/docs/stable/null-handling#nulls-and-sorting
-- CREATE INDEX IF NOT EXISTS ix_hangfire_jobqueue_fetchedat_queue_jobid ON jobqueue USING btree (fetchedat nulls first, queue, jobid);
CREATE INDEX "ix_hangfire_jobqueue_fetchedat_queue_jobid" ON "jobqueue" USING btree ("fetchedat", "queue", "jobid");
CREATE INDEX "ix_hangfire_jobqueue_queueandfetchedat" ON "jobqueue" ("queue", "fetchedat");
CREATE INDEX "ix_hangfire_jobqueue_jobidandqueue" ON "jobqueue" ("jobid", "queue");


--
-- Table structure for table `List`
--
CREATE TABLE IF NOT EXISTS "list"
(
    "id"          BIGSERIAL                 NOT NULL,
    "key"         TEXT                      NOT NULL,
    "value"       TEXT                      NULL,
    "expireat"    TIMESTAMP WITH TIME ZONE  NULL,
    "updatecount" INTEGER                   NOT NULL DEFAULT 0,
    PRIMARY KEY ("id")
);

CREATE INDEX "ix_hangfire_list_expireat" ON "list" ("expireat");


--
-- Table structure for table `Server`
--
CREATE TABLE IF NOT EXISTS "server"
(
    "id"            TEXT                        NOT NULL,
    "data"          jsonb                       NULL,
    "lastheartbeat" TIMESTAMP WITH TIME ZONE    NOT NULL,
    "updatecount"   INTEGER                     NOT NULL DEFAULT 0,
    PRIMARY KEY ("id")
);


--
-- Table structure for table `Set`
--
CREATE TABLE IF NOT EXISTS "set"
(
    "id"          BIGSERIAL                 NOT NULL,
    "key"         TEXT                      NOT NULL,
    "score"       FLOAT8                    NOT NULL,
    "value"       TEXT                      NOT NULL,
    "expireat"    TIMESTAMP WITH TIME ZONE  NULL,
    "updatecount" INTEGER                   NOT NULL DEFAULT 0,
    PRIMARY KEY ("id"),
    UNIQUE ("key", "value")
);

CREATE INDEX "ix_hangfire_set_expireat" ON "set" ("expireat");
CREATE INDEX "ix_hangfire_set_key_score" ON "set" ("key" ASC, "score" ASC);


--
-- Table structure for table `JobParameter`
--
CREATE TABLE IF NOT EXISTS "jobparameter"
(
    "id"          BIGSERIAL    NOT NULL,
    "jobid"       BIGINT      NOT NULL,
    "name"        TEXT        NOT NULL,
    "value"       TEXT        NULL,
    "updatecount" INTEGER     NOT NULL DEFAULT 0,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("jobid") REFERENCES "job" ("id") ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX "ix_hangfire_jobparameter_jobidandname" ON "jobparameter" ("jobid", "name");


--
-- Table structure for table `Lock`
--
CREATE TABLE IF NOT EXISTS "lock"
(
    "resource"    TEXT                       NOT NULL,
    "updatecount" INTEGER                    NOT NULL DEFAULT 0,
    "acquired"    TIMESTAMP WITH TIME ZONE   NULL,
    UNIQUE ("resource")
);


--
-- Table structure for table `AggregatedCounter`
--
CREATE TABLE IF NOT EXISTS "aggregatedcounter"
(
    "id"        BIGSERIAL                   NOT NULL,
    "key"       TEXT                        NOT NULL,
    "value"     BIGINT                      NOT NULL,
    "expireat"  TIMESTAMP WITH TIME ZONE    NULL,
    PRIMARY KEY ("id"),
    UNIQUE ("key")
);


UPDATE "schema" SET "version" = 1 WHERE "version" < 1;

RESET search_path;