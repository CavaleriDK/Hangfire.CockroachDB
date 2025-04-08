# Hangfire.CockroachDB

This is an plugin to the Hangfire to enable CockroachDB as a storage system.
Read about hangfire here: https://github.com/HangfireIO/Hangfire#overview
and here: http://hangfire.io/

## Instructions

### For .NET

Install Hangfire, see https://github.com/HangfireIO/Hangfire#installation

Download all files from this repository, add the Hangfire.CockroachDB.csproj to your solution.
Reference it in your project, and you are ready to go by using:

```csharp
app.UseHangfireServer(new BackgroundJobServerOptions(),
  new PostgreSqlStorage("<connection string or its name>"));
app.UseHangfireDashboard();
```

### For ASP.NET Core

First, NuGet package needs installation.

- Hangfire.AspNetCore
- Hangfire.CockroachDB (Uses Npgsql 8)

Historically both packages were functionally the same up until the package version 1.9.11, the only difference was the underlying Npgsql dependency version. Afterwards, the support for Npgsql v5 has been dropped and now minimum required version is 8.0.0.

In `Startup.cs` _ConfigureServices(IServiceCollection services)_ method add the following line:

```csharp
services.AddHangfire(config =>
    config.UseCockroachDbStorage(c =>
        c.UseNpgsqlConnection(Configuration.GetConnectionString("HangfireConnection"))));
```

In Configure method, add these two lines:

```csharp
app.UseHangfireServer();
app.UseHangfireDashboard();
```

And... That's it. You are ready to go.

If you encounter any issues/bugs or have idea of a feature regarding Hangfire.CockroachDB, [create us an issue](https://github.com/CavaleriDK/Hangfire.CockroachDB/issues/new). Thanks!

### Enabling SSL support

SSL support can be enabled for Hangfire.PostgreSql library using the following mechanism:

```csharp
config.UseCockroachDbStorage(c =>
    c.UseNpgsqlConnection(
        Configuration.GetConnectionString("HangfireConnection"), // connection string,
        connection => // connection setup - gets called after instantiating the connection and before any calls to DB are made
        {
            connection.ProvideClientCertificatesCallback += clientCerts =>
            {
                clientCerts.Add(X509Certificate.CreateFromCertFile("[CERT_FILENAME]"));
            };
        }
    )
);
```

### License

Copyright © 2014-2024 Frank Hommers https://github.com/hangfire-postgres/Hangfire.PostgreSql.

Collaborators:
Frank Hommers (frankhommers), Vytautas Kasparavičius (vytautask), Žygimantas Arūna (azygis) 

Contributors:
Andrew Armstrong (Plasma), Burhan Irmikci (barhun), Zachary Sims(zsims), kgamecarter, Stafford Williams (staff0rd), briangweber, Viktor Svyatokha (ahydrax), Christopher Dresel (Dresel), Vincent Vrijburg, David Roth (davidroth) and Ivan Tiniakov (Tinyakov).

Hangfire.PostgreSql is an Open Source project licensed under the terms of the LGPLv3 license. Please see http://www.gnu.org/licenses/lgpl-3.0.html for license text or COPYING.LESSER file distributed with the source code.

This work is based on the work of Sergey Odinokov, author of Hangfire. <http://hangfire.io/>

### Related Projects

- [Hangfire.Core](https://github.com/HangfireIO/Hangfire)
