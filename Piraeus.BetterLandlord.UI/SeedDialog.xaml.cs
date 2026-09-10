using System.Windows;
using System.Windows.Input;
using Piraeus.BetterLandlord.UI.Ipc;
using Piraeus.BetterLandlord.UI.Services;

namespace Piraeus.BetterLandlord.UI;

public partial class SeedDialog : Window
{
    private readonly UiPipeClient _pipeClient;
    private readonly bool _ownsPipeClient;

    /// <summary>
    /// Create a seed dialog. If pipeClient is null (standalone mode),
    /// creates its own short-lived pipe connection.
    /// </summary>
    public SeedDialog(UiPipeClient? pipeClient = null)
    {
        InitializeComponent();

        if (pipeClient != null)
        {
            _pipeClient = pipeClient;
            _ownsPipeClient = false;
        }
        else
        {
            _pipeClient = new UiPipeClient();
            _ownsPipeClient = true;
        }

        // The game's TTS flow clears the clipboard (TTButton do_call), which
        // leaves Ctrl+V empty for a seed copied before launch. Paste inherits
        // the remembered copy — user-initiated, nothing is ever prefilled.
        SeedInput.CommandBindings.Add(
            new CommandBinding(ApplicationCommands.Paste, SeedInput_Paste));

        Loaded += (s, e) =>
        {
            // Track copies made after launch; the startup capture in App
            // already holds the pre-launch one.
            ClipboardHelper.RememberClipboardText();

            Activate();
            SeedInput.Focus();
            Keyboard.Focus(SeedInput);
            Watermark.Visibility = string.IsNullOrEmpty(SeedInput.Text)
                ? Visibility.Visible : Visibility.Collapsed;
        };
    }

    private void SeedInput_TextChanged(object sender, System.Windows.Controls.TextChangedEventArgs e)
    {
        Watermark.Visibility = string.IsNullOrEmpty(SeedInput.Text)
            ? Visibility.Visible : Visibility.Collapsed;
    }

    private void Cancel_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }

    private void Confirm_Click(object sender, RoutedEventArgs e)
    {
        var input = SeedInput.Text;
        // O→0, I→1 canonicalization (same as Godot side)
        input = input.Replace('O', '0').Replace('I', '1');

        _pipeClient.SendSetSeed(input);
        DialogResult = true;
        Close();
    }

    private void SeedInput_Paste(object sender, ExecutedRoutedEventArgs e)
    {
        var text = ClipboardHelper.GetTextForPaste();
        if (!string.IsNullOrEmpty(text))
            SeedInput.SelectedText = text;
    }

    protected override void OnClosed(EventArgs e)
    {
        if (_ownsPipeClient)
            _pipeClient.Dispose();
        base.OnClosed(e);
    }
}
