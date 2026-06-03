using System.Text.Json;
using System.Text.Json.Serialization;

namespace Piraeus.BetterHistoryMod.Model;

/// <summary>
/// Handles Godot JSON.print quirk where a single-element array may be
/// serialized as a bare object instead of an array containing that object.
/// Both {"id":"x"} and [{"id":"x"}] are accepted during deserialization.
/// </summary>
public class SingleOrArrayConverter<T> : JsonConverter<List<T>>
{
    public override List<T>? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        return reader.TokenType switch
        {
            JsonTokenType.StartArray => JsonSerializer.Deserialize<List<T>>(ref reader, options),
            JsonTokenType.StartObject => new List<T>
            {
                JsonSerializer.Deserialize<T>(ref reader, options)!
            },
            JsonTokenType.Null => null,
            _ => throw new JsonException($"Expected array, object, or null for List<{typeof(T).Name}>, got {reader.TokenType}")
        };
    }

    public override void Write(Utf8JsonWriter writer, List<T> value, JsonSerializerOptions options)
    {
        // Always write as array — don't replicate Godot's quirk on write
        JsonSerializer.Serialize(writer, value, options);
    }
}
