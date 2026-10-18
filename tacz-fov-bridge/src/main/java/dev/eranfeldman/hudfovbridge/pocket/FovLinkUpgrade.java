package dev.eranfeldman.hudfovbridge.pocket;

import dan200.computercraft.api.pocket.AbstractPocketUpgrade;
import dan200.computercraft.api.pocket.IPocketAccess;
import dan200.computercraft.api.peripheral.IPeripheral;
import dan200.computercraft.api.pocket.IPocketUpgrade;
import dan200.computercraft.api.upgrades.UpgradeType;
import dev.eranfeldman.hudfovbridge.registry.BridgeRegistries;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.ItemStack;

public final class FovLinkUpgrade extends AbstractPocketUpgrade {
    public FovLinkUpgrade(ItemStack stack) {
        super(Component.literal("HUD FOV Link"), stack);
    }

    @Override
    public UpgradeType<? extends IPocketUpgrade> getType() {
        return BridgeRegistries.FOV_LINK.get();
    }

    @Override
    public IPeripheral createPeripheral(IPocketAccess access) {
        return new FovPeripheral(access);
    }
}
