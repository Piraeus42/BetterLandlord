using System.Runtime.InteropServices;
using System.Windows;

namespace Piraeus.BetterLandlord.UI.Services;

/// <summary>
/// The Win32 clipboard lets only one process hold it open and OpenClipboard
/// fails outright with CLIPBRD_E_CANT_OPEN instead of waiting. The game's TTS
/// clear/restore cycle and clipboard managers, IMEs and screenshot tools on
/// player machines hold the clipboard briefly and unpredictably, so a plain
/// Clipboard.SetDataObject throws sporadically. Retry across that contention
/// window, then fall back to a session-only copy that skips the flush (the
/// step that must open the clipboard); the app stays resident, so the text
/// stays pasteable even without the flush.
/// </summary>
public static class ClipboardHelper
{
    private const int MaxAttempts = 8;
    private const int RetryDelayMs = 25;

    // Last text seen on the clipboard. The game's TTS flow clears it (TTButton
    // do_call), so the pre-launch copy only survives here.
    private static string? _lastKnownText;

    /// <summary>
    /// Remembers the current clipboard text when it has any. Called once at
    /// app startup (captures the player's pre-launch copy before the game can
    /// clear it) and again whenever seed input opens, so copies made after
    /// launch take precedence.
    /// </summary>
    public static void RememberClipboardText()
    {
        var current = TryGetText();
        if (!string.IsNullOrEmpty(current))
            _lastKnownText = current;
    }

    /// <summary>
    /// Text a paste should insert: the live clipboard when it has text, else
    /// the remembered copy — without the fallback, Ctrl+V comes up empty
    /// after the game cleared the clipboard.
    /// </summary>
    public static string? GetTextForPaste()
        => TryGetText() ?? _lastKnownText;

    /// <summary>
    /// Copies text to the clipboard, tolerating transient clipboard
    /// contention. Returns false when every attempt failed; callers should
    /// surface that in status text instead of letting the exception reach
    /// the dispatcher error dialog.
    /// </summary>
    public static bool TryCopyText(string text)
    {
        for (var attempt = 1; attempt <= MaxAttempts; attempt++)
        {
            try
            {
                Clipboard.SetDataObject(text, attempt < MaxAttempts);
                return true;
            }
            catch (ExternalException) when (attempt < MaxAttempts)
            {
                Thread.Sleep(RetryDelayMs);
            }
            catch (ExternalException)
            {
                return false;
            }
        }

        return false;
    }

    /// <summary>
    /// Reads clipboard text with the same contention tolerance as
    /// TryCopyText. Returns null when the clipboard holds no text or stayed
    /// locked through every attempt.
    /// </summary>
    public static string? TryGetText()
    {
        for (var attempt = 1; attempt <= MaxAttempts; attempt++)
        {
            try
            {
                return Clipboard.ContainsText() ? Clipboard.GetText() : null;
            }
            catch (ExternalException) when (attempt < MaxAttempts)
            {
                Thread.Sleep(RetryDelayMs);
            }
            catch (ExternalException)
            {
                return null;
            }
        }

        return null;
    }
}
