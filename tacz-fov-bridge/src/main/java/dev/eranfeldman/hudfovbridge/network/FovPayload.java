package dev.eranfeldman.hudfovbridge.network;

import dev.eranfeldman.hudfovbridge.state.FovSamples;
import io.netty.buffer.ByteBuf;
import net.minecraft.network.codec.ByteBufCodecs;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerPlayer;
import net.neoforged.neoforge.network.handling.IPayloadContext;

public record FovPayload(float fov) implements CustomPacketPayload {
    public static final Type<FovPayload> TYPE = new Type<>(ResourceLocation.fromNamespaceAndPath("hudfovbridge", "fov"));
    public static final StreamCodec<ByteBuf, FovPayload> STREAM_CODEC = StreamCodec.composite(
        ByteBufCodecs.FLOAT, FovPayload::fov, FovPayload::new
    );

    @Override
    public Type<? extends CustomPacketPayload> type() {
        return TYPE;
    }

    public static void handle(FovPayload payload, IPayloadContext context) {
        if (context.player() instanceof ServerPlayer player) FovSamples.update(player, payload.fov());
    }
}
