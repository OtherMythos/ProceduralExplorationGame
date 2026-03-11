
::Items <- array(ItemId.MAX, null);

//-------------------------------
::Items[ItemId.NONE] = ItemDef("None", "None.", null, ItemType.NONE, 1, EquippableId.NONE);

::Items[ItemId.HEALTH_POTION] = ItemDef("Health Potion", "A potion of health. Bubbles gently inside a cast glass flask.", "smallPotion.voxMesh", ItemType.DRINK, 5, null, EquippableId.NONE);
::Items[ItemId.LARGE_HEALTH_POTION] = ItemDef("Large Health Potion", "A large potion of health.", "largePotion.voxMesh", ItemType.DRINK, 10, null, EquippableId.NONE);

::Items[ItemId.SIMPLE_SWORD] = ItemDef("Simple Sword", "A cheap, weak sword. Relatively blunt for something claiming to be a sword.", "simpleSword.voxMesh", ItemType.EQUIPPABLE, 5, null, EquippableId.REGULAR_SWORD, ItemEquipTransformType.BASIC_SWORD);
::Items[ItemId.SIMPLE_SHIELD] = ItemDef("Simple Shield", "An un-interesting shield. Provides minimal protection.", "simpleShield.voxMesh", ItemType.EQUIPPABLE, 5, null, EquippableId.REGULAR_SHIELD, ItemEquipTransformType.BASIC_SHIELD);
::Items[ItemId.SIMPLE_TWO_HANDED_SWORD] = ItemDef("Simple Two Handed sword", "A two handed sword as blunt as it is big.", "simpleTwoHandedSword.voxMesh", ItemType.EQUIPPABLE, 5, null, EquippableId.REGULAR_TWO_HANDED_SWORD, ItemEquipTransformType.BASIC_TWO_HANDED_SWORD);
::Items[ItemId.BONE_MACE] = ItemDef("Bone Mace", "Large clobbering clump of ex-person erecter.", "boneMace.voxMesh", ItemType.EQUIPPABLE, 5, null, EquippableId.REGULAR_SWORD, ItemEquipTransformType.BASIC_SWORD);
::Items[ItemId.SIMPLE_STAFF] = ItemDef("Simple Staff", "A rickety magic staff.", "simpleStaff.voxMesh", ItemType.EQUIPPABLE, 5, null, EquippableId.REGULAR_STAFF, ItemEquipTransformType.BASIC_STAFF);

::Items[ItemId.BOOK_OF_GOBLIN_STORIES] = ItemDef("Book of Goblin Stories", "A crudely written tomb of popular goblin stories.", "readables.brownBook.voxMesh", ItemType.LORE_CONTENT, 0, "BookOfGoblinTales.nut", EquippableId.NONE);
::Items[ItemId.APPLE] = ItemDef("Apple", "Fibrous fruit.", "fruit.apple.voxMesh", ItemType.EAT, 5, null, EquippableId.NONE);
::Items[ItemId.COCONUT] = ItemDef("Coconut", "Weirdly milky for a fruit.", "fruit.coconut.voxMesh", ItemType.EAT, 5, null, EquippableId.NONE);
::Items[ItemId.RED_BERRIES] = ItemDef("Red Berries", "Red and fruity.", "fruit.redBerries.voxMesh", ItemType.EAT, 5, null, EquippableId.NONE);
::Items[ItemId.FLOWER_WHITE] = ItemDef("White Flower", "A white delecate flower.", "flower.flowerWhite.voxMesh", ItemType.EAT, 5, null, EquippableId.NONE);
::Items[ItemId.FLOWER_RED] = ItemDef("Red Flower", "A red delecate flower.", "flower.flowerRed.voxMesh", ItemType.EAT, 5, null, EquippableId.NONE);
::Items[ItemId.FLOWER_PURPLE] = ItemDef("Purple Flower", "A purple delecate flower.", "flower.flowerPurple.voxMesh", ItemType.EAT, 5, null, EquippableId.NONE);
::Items[ItemId.MUSHROOM_1] = ItemDef("Mushroom", "A peculiar fungal growth.", "mushrooms.mushroom.1.voxMesh", ItemType.EAT, 5, null, EquippableId.NONE);
::Items[ItemId.MUSHROOM_2] = ItemDef("Mushroom", "A peculiar fungal growth.", "mushrooms.mushroom.2.voxMesh", ItemType.EAT, 5, null, EquippableId.NONE);
::Items[ItemId.MUSHROOM_3] = ItemDef("Mushroom", "A peculiar fungal growth.", "mushrooms.mushroom.3.voxMesh", ItemType.EAT, 5, null, EquippableId.NONE);
::Items[ItemId.MAGMA_SHROOM] = ItemDef("Magma Shroom", "A peculiar mushroom that radiates heat.", "mushrooms.mushroom.magma.voxMesh", ItemType.EAT, 10, null, EquippableId.NONE);
::Items[ItemId.MESSAGE_IN_A_BOTTLE] = ItemDef("Message in a Bottle", "A mysterious message sealed in a glass bottle. It has washed ashore from distant seas.", "collectables.messageInABottle.voxMesh", ItemType.MESSAGE_IN_A_BOTTLE, 0, null, EquippableId.NONE);
::Items[ItemId.SAND_URN] = ItemDef("Haunted Urn", "An ancient urn that has travelled across the desert sands. It contains something mysterious.", "collectables.hauntedUrn.voxMesh", ItemType.SAND_URN, 0, null, EquippableId.NONE);
::Items[ItemId.NOTE_SCRAP] = ItemDef("Note Scrap", "A scrap of paper found inside the message in a bottle.", "readables.noteScrap.voxMesh", ItemType.LORE_CONTENT, 0, null, EquippableId.NONE);
::Items[ItemId.FALLEN_STAR] = ItemDef("Fallen Star", "A glimmering star that has fallen from the heavens.", "fallenStar.voxMesh", ItemType.ITEM, 5, null, EquippableId.NONE);
::Items[ItemId.BLUE_ORE] = ItemDef("Blue Ore", "A chunk of blue ore mined from a rock.", "ore.blueOre.voxMesh", ItemType.ITEM, 5, null, EquippableId.NONE);
//-------------------------------

::ItemHelper.itemToStats <- function(item){
    local stat = ::StatsEntry();

    //Populate sell and scrap values from item definition
    stat.mSellValue = ::Items[item].getSellValue();
    stat.mScrapValue = ::Items[item].getScrapVal();

    switch(item){
        case ItemId.NONE: return stat;
        case ItemId.HEALTH_POTION: {
            stat.mRestorativeHealth = 10;
            return stat;
        }
        case ItemId.APPLE:
        case ItemId.RED_BERRIES:
        case ItemId.COCONUT:
        case ItemId.MUSHROOM_2:
        case ItemId.MUSHROOM_3: {
            stat.mRestorativeHealth = 5;
            return stat;
        }
        case ItemId.MUSHROOM_1: {
            stat.mRestorativeHealth = -5;
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