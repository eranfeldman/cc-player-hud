package dev.eranfeldman.hudfovbridge.registry;

import dan200.computercraft.api.pocket.IPocketUpgrade;
import dan200.computercraft.api.upgrades.UpgradeType;
import dev.eranfeldman.hudfovbridge.HudFovBridge;
import dev.eranfeldman.hudfovbridge.pocket.FovLinkUpgrade;
import net.minecraft.world.item.Item;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

public final class BridgeRegistries {
    public static final DeferredRegister.Items ITEMS = DeferredRegister.createItems(HudFovBridge.MOD_ID);
    public static final DeferredHolder<Item, Item> FOV_LINK_ITEM = ITEMS.registerSimpleItem("fov_link_upgrade");
    public static final DeferredRegister<UpgradeType<? extends IPocketUpgrade>> POCKET_UPGRADES =
        DeferredRegister.create(IPocketUpgrade.typeRegistry(), HudFovBridge.MOD_ID);
    public static final DeferredHolder<UpgradeType<? extends IPocketUpgrade>, UpgradeType<FovLinkUpgrade>> FOV_LINK =
        POCKET_UPGRADES.register("fov_link", () -> UpgradeType.simpleWithCustomItem(FovLinkUpgrade::new));

    private BridgeRegistries() {}
}
