
::Items <- array(ItemId.MAX, null);

//-------------------------------
::Items[ItemId.NONE] = ItemDef("None", "None", null, null ItemType.NONE, 1, EquippableId.NONE);

::Items[ItemId.HEALTH_POTION] = ItemDef("Health Potion", "A potion of health. Bubbles gently inside a cast glass flask.", "smallPotion.voxMesh", "item_healthPotion", ItemType.CONSUMABLE, 5, null, EquippableId.NONE);
::Items[ItemId.LARGE_HEALTH_POTION] = ItemDef("Large Health Potion", "A large potion of health.", "largePotion.voxMesh", "item_largeHealthPotion", ItemType.CONSUMABLE, 10, null, EquippableId.NONE);

::Items[ItemId.SIMPLE_SWORD] = ItemDef("Simple Sword", "A cheap, weak sword. Relatively blunt for something claiming to be a sword.", "simpleSword.voxMesh", "item_simpleSword", ItemType.EQUIPPABLE, 5, null, EquippableId.REGULAR_SWORD, ItemEquipTransformType.BASIC_SWORD);
::Items[ItemId.SIMPLE_SHIELD] = ItemDef("Simple Shield", "An un-interesting shield. Provides minimal protection.", "simpleShield.voxMesh", "item_simpleShield", ItemType.EQUIPPABLE, 5, null, EquippableId.REGULAR_SHIELD, ItemEquipTransformType.BASIC_SHIELD);
::Items[ItemId.SIMPLE_TWO_HANDED_SWORD] = ItemDef("Simple Two Handed sword", "A two handed sword as blunt as it is big.", "simpleTwoHandedSword.voxMesh", "item_simpleTwoHandedSword", ItemType.EQUIPPABLE, 5, null, EquippableId.REGULAR_TWO_HANDED_SWORD, ItemEquipTransformType.BASIC_TWO_HANDED_SWORD);
::Items[ItemId.BONE_MACE] = ItemDef("Bone Mace", "Large clobbering clump of ex-person erecter.", "boneMace.voxMesh", "item_boneMace", ItemType.EQUIPPABLE, 5, null, EquippableId.REGULAR_SWORD, ItemEquipTransformType.BASIC_SWORD);

::Items[ItemId.BOOK_OF_GOBLIN_STORIES] = ItemDef("Book of Goblin Stories", "A crudely written tomb of popular goblin stories", "boneMace.voxMesh", "item_boneMace", ItemType.LORE_CONTENT, 0, "BookOfGoblinTales.nut", EquippableId.NONE);
::Items[ItemId.APPLE] = ItemDef("Apple", "Fibrous fruit", "apple.voxMesh", "item_apple", ItemType.CONSUMABLE, 5, null, EquippableId.NONE);
//-------------------------------

::ItemHelper.itemToStats <- function(item){
    local stat = ::StatsEntry();

    switch(item){
        case ItemId.NONE: return stat;
        case ItemId.HEALTH_POTION: {
            stat.mRestorativeHealth = 10;
            return stat;
        }
        case ItemId.APPLE: {
            stat.mRestorativeHealth = 5;
            return stat;
        }
        case ItemId.LARGE_HEALTH_POTION: {
            stat.mRestorativeHealth = 20;
            return stat;
        }
        case ItemId.BONE_MACE:
        case ItemId.SIMPLE_SWORD: {
            stat.mAttack = 2;
            return stat;
        }
        case ItemId.SIMPLE_TWO_HANDED_SWORD: {
            stat.mAttack = 10;
            return stat;
        }
        case ItemId.SIMPLE_SHIELD: {
            stat.mDefense = 5;
            return stat;
        }
        default:{

        }
    }

    return stat;
}