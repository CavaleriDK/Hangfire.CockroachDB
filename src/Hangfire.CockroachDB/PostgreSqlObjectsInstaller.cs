// This file is part of Hangfire.PostgreSql.
// Copyright © 2014 Frank Hommers <http://hmm.rs/Hangfire.PostgreSql>.
// 
// Hangfire.PostgreSql is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as 
// published by the Free Software Foundation, either version 3 
// of the License, or any later version.
// 
// Hangfire.PostgreSql  is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public 
// License along with Hangfire.PostgreSql. If not, see <http://www.gnu.org/licenses/>.
//
// This work is based on the work of Sergey Odinokov, author of 
// Hangfire. <http://hangfire.io/>
//   
//    Special thanks goes to him.

using System;
using System.Data;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Resources;
using Hangfire.Logging;
using Npgsql;

namespace Hangfire.CockroachDB
{
  public static class PostgreSqlObjectsInstaller
  {
    private static readonly ILog _logger = LogProvider.GetLogger(typeof(PostgreSqlStorage));

    public static void Install(NpgsqlConnection connection, string schemaName = "hangfire", bool disableAutoCommitBeforeDdl = false)
    {
      if (connection == null)
      {
        throw new ArgumentNullException(nameof(connection));
      }

      _logger.Info("Start installing Hangfire SQL objects...");
      
      int currentVersion = GetCurrentSchemaVersion(connection, schemaName);
      int targetVersion = 1;
      while (true)
      {
          string scriptName = $"Hangfire.CockroachDB.Scripts.Install.v{targetVersion.ToString(CultureInfo.InvariantCulture)}.sql";
          string script;
          try
          {
              script = GetStringResource(typeof(PostgreSqlObjectsInstaller).GetTypeInfo().Assembly, scriptName);
          }
          catch (MissingManifestResourceException)
          {
              break;
          }

          if (schemaName != "hangfire")
          {
              script = script.Replace("'hangfire'", $"'{schemaName}'").Replace(@"""hangfire""", $@"""{schemaName}""");
          }

          if (currentVersion < targetVersion)
          {
              _logger.Info($"Installing script {scriptName} for version {targetVersion}");

              try
              {
                  if (disableAutoCommitBeforeDdl)
                  {
                      using NpgsqlCommand disableAutoCommit = new("SET autocommit_before_ddl = off", connection);
                      disableAutoCommit.ExecuteNonQuery();
                  }

                  using NpgsqlTransaction transaction = connection.BeginTransaction(IsolationLevel.Serializable);
                  using NpgsqlCommand command = new(script, connection, transaction);
                  command.CommandTimeout = 120;
                  command.ExecuteNonQuery();
                  transaction.Commit();
                  currentVersion = GetCurrentSchemaVersion(connection, schemaName);
              }
              catch (PostgresException ex)
              {
                  _logger.ErrorException("PostgresException", ex);
                  throw;
              }
          }
          else
          {
              _logger.Info($"Skipping script {scriptName} for version {targetVersion} (already applied)");
          }

          targetVersion++;
      }

      _logger.Info("Hangfire SQL objects installed.");
    }

    private static int GetCurrentSchemaVersion(NpgsqlConnection connection, string schemaName)
    {
      try
      {
        using NpgsqlCommand command = new($@"SELECT ""version"" FROM ""{schemaName}"".""schema""", connection);
        object result = command.ExecuteScalar();
        if (result != null && result != DBNull.Value)
        {
          return Convert.ToInt32(result);
        }
        return 0;
      }
      catch (PostgresException ex)
      {
        if (ex.SqlState.Equals(PostgresErrorCodes.UndefinedTable)) //42P01: Relation (table) does not exist. So no schema table yet.
        {
          return 0;
        }

        throw;
      }
    }

    private static string GetStringResource(Assembly assembly, string resourceName)
    {
      using Stream stream = assembly.GetManifestResourceStream(resourceName);
      if (stream == null)
      {
        throw new MissingManifestResourceException($"Requested resource `{resourceName}` was not found in the assembly `{assembly}`.");
      }

      using StreamReader reader = new(stream);
      return reader.ReadToEnd();
    }
  }
}
