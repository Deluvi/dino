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

        this.device = new ALC.Device(null);
        if (device == null) {
            stderr.printf("Could not open a device!\n");
            return;
        }

        this.ctx = new ALC.Context(device, null);
        if (ctx == null || !ctx.make_current()) {
            stderr.printf("Could not set a context!\n");
            return;
        }

        {
            string? name = null;
            if (device.is_extension_present("ALC_ENUMERATE_ALL_EXT")) {
                name = device.get_string(ALC.ALL_DEVICES_SPECIFIER);
            }

            if (name == null || device.get_error() != ALC.Error.NO_ERROR) {
                name = device.get_string(ALC.DEVICE_SPECIFIER);
            }

            print(@"Opened \"$name\"\n");
        }

        {
            this.format = AL.BufferFormat.MONO16;
            int sampleRate = 44100;
            var audio_file = GLib.File.new_for_uri("resource:///im/dino/Dino/openal-notification-sound/message2_mono_16_44100.raw");
            string etag;
            var data = audio_file.load_bytes(null, out etag);

            AL.gen_buffer(1, out this.buffer);
            this.buffer.set_data(this.format, data.get_data(), data.length, sampleRate);

            if (!AL.is_buffer(this.buffer)) {
                shutdown();
                return;
            }
        }

        AL.gen_source(1, out this.source);
        source.set_parami(AL.BUFFER, (AL.ALint)this.buffer);
        if (AL.get_error() != AL.Error.NO_ERROR) {
            print("Failed to setup sound source\n");
            return;
        }

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
}

}
