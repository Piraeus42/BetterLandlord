using System.Windows;
using System.Windows.Input;
using Piraeus.BetterHistory.UI.Ipc;

namespace Piraeus.BetterHistory.UI;

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

        Loaded += (s, e) =>
        {
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

    protected override void OnClosed(EventArgs e)
    {
        if (_ownsPipeClient)
            _pipeClient.Dispose();
        base.OnClosed(e);
    }
}
