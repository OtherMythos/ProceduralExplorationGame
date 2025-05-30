enum ProjectileId{
    NONE,

    FIREBALL,
    AREA,
    FIRE_AREA,

    MAX
};

::ProjectileDef <- class{
    mDamage = 0;
    mSize = null;
    mMesh = null;
    mLifetime = 100;
    mModelScale = null;
    constructor(damage, size=null, mesh=null, lifetime=100, modelScale=null){
        mDamage = damage;
        mSize = size;
        mMesh = mesh;
        mLifetime = lifetime;
        mModelScale = modelScale;
    }
};

::Projectiles <- array(ProjectileId.MAX, null);

::Projectiles[ProjectileId.NONE] = ProjectileDef(10);
::Projectiles[ProjectileId.FIREBALL] = ProjectileDef(10, Vec3(1, 1, 1), "fireballProjectile.mesh", 1000, Vec3(0.25, 0.25, 1));
::Projectiles[ProjectileId.AREA] = ProjectileDef(10, Vec3(5, 5, 5));
::Projectiles[ProjectileId.FIRE_AREA] = ProjectileDef(10, Vec3(10, 10, 10), "Cylinder.mesh", 2);