package dev.eranfeldman.hudfovbridge.state;

import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import net.minecraft.server.level.ServerPlayer;
import net.neoforged.neoforge.event.entity.player.PlayerEvent;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import dev.eranfeldman.hudfovbridge.HudFovBridge;

@EventBusSubscriber(modid = HudFovBridge.MOD_ID)
public final class FovSamples {
    private static final long MAX_AGE_NANOS = 2_000_000_000L;
    private static final ConcurrentHashMap<UUID, Sample> SAMPLES = new ConcurrentHashMap<>();

    private FovSamples() {}

    public static void update(ServerPlayer player, float fov) {
        if (!Float.isFinite(fov) || fov < 1.0f || fov > 179.0f) return;
        UUID id = player.getUUID();
        long now = System.nanoTime();
        SAMPLES.compute(id, (ignored, previous) -> {
            if (previous != null && now - previous.timestampNanos < 25_000_000L) return previous;
            return new Sample(fov, now);
        });
    }

    public static Double get(ServerPlayer player) {
        Sample sample = freshSample(player);
        return sample == null ? null : (double) sample.fov;
    }

    public static boolean isFresh(ServerPlayer player) {
        return freshSample(player) != null;
    }

    private static Sample freshSample(ServerPlayer player) {
        Sample sample = SAMPLES.get(player.getUUID());
        if (sample == null) return null;
        if (System.nanoTime() - sample.timestampNanos > MAX_AGE_NANOS) {
            SAMPLES.remove(player.getUUID(), sample);
            return null;
        }
        return sample;
    }

    @SubscribeEvent
    public static void onLogout(PlayerEvent.PlayerLoggedOutEvent event) {
        SAMPLES.remove(event.getEntity().getUUID());
    }

    private record Sample(float fov, long timestampNanos) {}
}
