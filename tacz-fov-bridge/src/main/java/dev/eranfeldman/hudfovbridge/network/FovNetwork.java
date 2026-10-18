package dev.eranfeldman.hudfovbridge.network;

import net.neoforged.neoforge.network.event.RegisterPayloadHandlersEvent;

public final class FovNetwork {
    private FovNetwork() {}

    public static void registerPayloads(RegisterPayloadHandlersEvent event) {
        event.registrar("1").optional().playToServer(FovPayload.TYPE, FovPayload.STREAM_CODEC, FovPayload::handle);
    }
}
