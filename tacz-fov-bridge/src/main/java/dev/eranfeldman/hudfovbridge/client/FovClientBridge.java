package dev.eranfeldman.hudfovbridge.client;

import dev.eranfeldman.hudfovbridge.HudFovBridge;
import dev.eranfeldman.hudfovbridge.network.FovPayload;
import net.minecraft.client.Minecraft;
import net.minecraft.client.player.LocalPlayer;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.EventPriority;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.client.event.ComputeFovModifierEvent;
import net.neoforged.neoforge.client.event.ViewportEvent;
import net.neoforged.neoforge.network.PacketDistributor;

@EventBusSubscriber(modid = HudFovBridge.MOD_ID, value = Dist.CLIENT)
public final class FovClientBridge {
    private static final long SEND_INTERVAL_NANOS = 100_000_000L;
    private static final long HEARTBEAT_NANOS = 1_000_000_000L;
    private static final long BASE_FOV_MAX_AGE_NANOS = 100_000_000L;
    private static final float MIN_CHANGE = 0.05f;
    private static long lastSentAt;
    private static long baseFovAt;
    private static double baseFov = Double.NaN;
    private static float lastSentFov = Float.NaN;

    private FovClientBridge() {}

    @SubscribeEvent(priority = EventPriority.LOWEST)
    public static void onComputeFov(ViewportEvent.ComputeFov event) {
        Minecraft minecraft = Minecraft.getInstance();
        LocalPlayer player = minecraft.player;
        if (!event.usedConfiguredFov() || player == null || event.getCamera().getEntity() != player) return;

        double fov = event.getFOV();
        if (!Double.isFinite(fov) || fov < 1.0 || fov > 179.0) return;
        baseFov = fov;
        baseFovAt = System.nanoTime();
    }

    @SubscribeEvent(priority = EventPriority.LOWEST)
    public static void onComputeFovModifier(ComputeFovModifierEvent event) {
        Minecraft minecraft = Minecraft.getInstance();
        if (event.getPlayer() != minecraft.player || !Double.isFinite(baseFov)) return;

        long now = System.nanoTime();
        if (now - baseFovAt > BASE_FOV_MAX_AGE_NANOS) return;
        float fov = (float) (baseFov * event.getNewFovModifier());
        if (!Float.isFinite(fov) || fov < 1.0f || fov > 179.0f) return;
        if (now - lastSentAt < SEND_INTERVAL_NANOS) return;
        if (Float.isFinite(lastSentFov) && Math.abs(fov - lastSentFov) < MIN_CHANGE
            && now - lastSentAt < HEARTBEAT_NANOS) return;

        PacketDistributor.sendToServer(new FovPayload(fov));
        lastSentAt = now;
        lastSentFov = fov;
    }
}
