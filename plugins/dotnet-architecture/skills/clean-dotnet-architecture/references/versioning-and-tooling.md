# Always use the latest versions

Target the latest stable .NET SDK/runtime, and keep every NuGet package (and any other
tooling — EF Core, analyzers, SDKs, project file schema) on its latest stable version.
When scaffolding a new project or touching an existing one, check for and apply available
upgrades rather than leaving versions stale — don't pin to an older version without a
concrete reason.
