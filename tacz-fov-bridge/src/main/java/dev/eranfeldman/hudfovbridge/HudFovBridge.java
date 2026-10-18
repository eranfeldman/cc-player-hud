package dev.eranfeldman.hudfovbridge;

import dev.eranfeldman.hudfovbridge.network.FovNetwork;
import dev.eranfeldman.hudfovbridge.registry.BridgeRegistries;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.common.Mod;

@Mod(HudFovBridge.MOD_ID)
public final class HudFovBridge {
    public static final String MOD_ID = "hudfovbridge";

    public HudFovBridge(IEventBus modBus) {
        BridgeRegistries.ITEMS.register(modBus);
        BridgeRegistries.POCKET_UPGRADES.register(modBus);
        modBus.addListener(FovNetwork::registerPayloads);
    }
}
