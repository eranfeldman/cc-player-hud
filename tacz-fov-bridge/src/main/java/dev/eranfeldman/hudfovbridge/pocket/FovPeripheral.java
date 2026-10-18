package dev.eranfeldman.hudfovbridge.pocket;

import dan200.computercraft.api.lua.IArguments;
import dan200.computercraft.api.lua.ILuaContext;
import dan200.computercraft.api.lua.LuaException;
import dan200.computercraft.api.lua.MethodResult;
import dan200.computercraft.api.peripheral.IDynamicPeripheral;
import dan200.computercraft.api.peripheral.IComputerAccess;
import dan200.computercraft.api.peripheral.IPeripheral;
import dan200.computercraft.api.pocket.IPocketAccess;
import dev.eranfeldman.hudfovbridge.state.FovSamples;
import net.minecraft.server.level.ServerPlayer;

public final class FovPeripheral implements IDynamicPeripheral {
    private static final String[] METHODS = { "getFov", "isReady" };
    private final IPocketAccess access;

    public FovPeripheral(IPocketAccess access) {
        this.access = access;
    }

    @Override
    public String getType() {
        return "hud_fov";
    }

    @Override
    public String[] getMethodNames() {
        return METHODS;
    }

    @Override
    public MethodResult callMethod(IComputerAccess computer, ILuaContext context, int method, IArguments arguments)
        throws LuaException {
        if (method == 0) {
            Double fov = access.getEntity() instanceof ServerPlayer player ? FovSamples.get(player) : null;
            return fov == null ? MethodResult.of() : MethodResult.of(fov);
        }
        if (method == 1) {
            return MethodResult.of(access.getEntity() instanceof ServerPlayer player && FovSamples.isFresh(player));
        }
        throw new LuaException("Unknown HUD FOV method");
    }

    @Override
    public boolean equals(IPeripheral other) {
        return other instanceof FovPeripheral peripheral && peripheral.access == access;
    }
}
