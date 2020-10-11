namespace Dino.Plugins.OpenAlNotificationSound {

public class Plugin : RootInterface, Object {

    public Dino.Application app;

    private ALC.Device device;
    private ALC.Context ctx;

    private AL.BufferFormat format;
    private AL.Buffer buffer;

    private AL.Source source;

    public void registered(Dino.Application app) {
        this.app = app;

        if (!setup_device() ||
            !setup_buffer() ||
            !setup_source()) {
            shutdown();
            return;
        }

        print_current();

        app.stream_interactor.get_module(NotificationEvents.IDENTITY).notify_content_item.connect((item, conversation) => {
            this.source.play();
        });
    }

    public void shutdown() {
        if (this.ctx == null) {
            return;
        }

        if (AL.is_source(this.source)) {
            AL.delete_source(1, ref this.source);
        }

        if (AL.is_buffer(this.buffer)) {
            AL.delete_buffer(1, ref this.buffer);
        }

        this.ctx = null;
        this.device = null;
    }

    bool setup_device() {
        this.device = new ALC.Device(null);
        if (device == null) {
            stderr.printf("[openal-notification]: Could not open a device!\n");
            return false;
        }

        this.ctx = new ALC.Context(device, new ALC.ALCint[] { 0, 0 });
        if (ctx == null || !ctx.make_current()) {
            stderr.printf("[openal-notification]: Could not set a context!\n");
            return false;
        }

        return true;
    }

    void print_current() {
        string? name = null;
        if (this.device.is_extension_present("ALC_ENUMERATE_ALL_EXT")) {
            name = device.get_string(ALC.ALL_DEVICES_SPECIFIER);
        }

        if (name == null || device.get_error() != ALC.Error.NO_ERROR) {
            name = device.get_string(ALC.DEVICE_SPECIFIER);
        }

        print(@"[openal-notification]: Opened \"$name\"\n");
    }

    bool setup_buffer() {
        this.format = AL.BufferFormat.MONO16;
        int sampleRate = 44100;
        var audio_file = GLib.File.new_for_uri("resource:///im/dino/Dino/openal-notification-sound/message2_mono_16_44100.raw");
        string etag;
        try {
            var data = audio_file.load_bytes(null, out etag);

            AL.gen_buffer(1, out this.buffer);
            this.buffer.set_data(this.format, data.get_data(), data.length, sampleRate);

            if (!AL.is_buffer(this.buffer)) {
                return false;
            }
        }
        catch (GLib.Error err) {
            var message = err.message;
            stderr.printf(@"[openal-notification]: Unable to load audio resource, \"$message\".");
            return false;
        }

        return true;
    }

    bool setup_source() {
        AL.gen_source(1, out this.source);

        if (AL.is_extension_present("AL_SOFT_direct_channels_remix")) {
            source.set_parami(AL.get_enum_value("AL_DIRECT_CHANNELS_SOFT"), 0x0002);
            if (AL.get_error() != AL.Error.NO_ERROR) {
                stderr.printf("[openal-notification]: Failed to setup sound source channel remix\n");
                return false;
            }
        }

        source.set_parami(AL.BUFFER, (AL.ALint)this.buffer);
        if (AL.get_error() != AL.Error.NO_ERROR) {
            stderr.printf("[openal-notification]: Failed to setup sound source buffer\n");
            return false;
        }

        return true;
    }
}

}
