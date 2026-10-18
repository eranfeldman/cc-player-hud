package dev.eranfeldman.hudfovbridge.pocket;

import dan200.computercraft.api.lua.IArguments;
import dan200.computercraft.api.lua.IDynamicLuaObject;
import dan200.computercraft.api.lua.ILuaAPI;
import dan200.computercraft.api.lua.ILuaContext;
import dan200.computercraft.api.lua.LuaException;
import dan200.computercraft.api.lua.MethodResult;
import dan200.computercraft.api.pocket.IPocketAccess;
import dev.eranfeldman.hudfovbridge.state.FovSamples;
import net.minecraft.server.level.ServerPlayer;

public final class FovLuaApi implements ILuaAPI, IDynamicLuaObject {
    private static final String[] METHODS = { "getFov", "isReady" };
    private final IPocketAccess pocket;

    public FovLuaApi(IPocketAccess pocket) {
        this.pocket = pocket;
    }

    @Override
    public String[] getNames() {
        return new String[0];
    }

    @Override
    public String getModuleName() {
        return "hudfovbridge.fov";
    }

    @Override
    public String[] getMethodNames() {
        return METHODS;
    }

    @Override
    public MethodResult callMethod(ILuaContext context, int method, IArguments arguments) throws LuaException {
        ServerPlayer player = pocket.getEntity() instanceof ServerPlayer owner ? owner : null;
        if (method == 0) {
            Double fov = player == null ? null : FovSamples.get(player);
            return fov == null ? MethodResult.of() : MethodResult.of(fov);
        }
        if (method == 1) return MethodResult.of(player != null && FovSamples.isFresh(player));
        throw new LuaException("Unknown HUD FOV method");
    }
}
