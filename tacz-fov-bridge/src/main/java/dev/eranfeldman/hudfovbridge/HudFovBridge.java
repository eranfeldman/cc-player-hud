package dev.eranfeldman.hudfovbridge;

import dev.eranfeldman.hudfovbridge.network.FovNetwork;
import dan200.computercraft.api.ComputerCraftAPI;
import dan200.computercraft.api.component.ComputerComponents;
import dan200.computercraft.api.pocket.IPocketAccess;
import dev.eranfeldman.hudfovbridge.pocket.FovLuaApi;
import net.neoforged.fml.event.lifecycle.FMLCommonSetupEvent;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.common.Mod;

@Mod(HudFovBridge.MOD_ID)
public final class HudFovBridge {
    public static final String MOD_ID = "hudfovbridge";

    public HudFovBridge(IEventBus modBus) {
        modBus.addListener(FovNetwork::registerPayloads);
        modBus.addListener(this::commonSetup);
    }

    private void commonSetup(FMLCommonSetupEvent event) {
        event.enqueueWork(() -> ComputerCraftAPI.registerAPIFactory(computer -> {
            IPocketAccess pocket = computer.getComponent(ComputerComponents.POCKET);
            return pocket == null ? null : new FovLuaApi(pocket);
        }));
    }
}
