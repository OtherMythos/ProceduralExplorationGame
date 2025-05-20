enum ProjectileId{
    NONE,

    FIREBALL,
    AREA,

    MAX
};

::ProjectileDef <- class{
    mDamage = 0;
    mSize = null;
    mMesh = null;
    constructor(damage, size=null, mesh=null){
        mDamage = damage;
        mSize = size;
        mMesh = mesh;
    }
};

::Projectiles <- array(ProjectileId.MAX, null);

::Projectiles[ProjectileId.NONE] = ProjectileDef(10);
::Projectiles[ProjectileId.FIREBALL] = ProjectileDef(10, ::Vec3_UNIT_SCALE, "cube.mesh");
::Projectiles[ProjectileId.AREA] = ProjectileDef(10, Vec3(5, 5, 5));