WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

WebApplication app = builder.Build();

app.UseHttpsRedirection();

app.MapGet("/", () => new
{
    Name = "Example Minimal API",
    Version = "0.0.1-preview",
    Status = "Running"
});

await app.RunAsync();