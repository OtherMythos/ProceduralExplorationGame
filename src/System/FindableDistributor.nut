::FindableDistributor <- class{

    //Common items: apples, berries, potions
    static mCommonItems_ = [
        ItemId.APPLE,
        ItemId.RED_BERRIES,
        ItemId.HEALTH_POTION,
        ItemId.LARGE_HEALTH_POTION
    ];

    //Rare items: fallen stars and message in a bottle
    static mRareItems_ = [
        ItemId.FALLEN_STAR,
        ItemId.MESSAGE_IN_A_BOTTLE
    ];

    function determineShopItems(width, height){
        local totalSlots = width * height;
        local items = array(totalSlots, null);
        local prices = array(totalSlots, null);

        //Calculate 25% empty slots
        local emptySlots = (totalSlots * 25) / 100;
        local filledSlots = totalSlots - emptySlots;

        //Determine number of rare items: between 1 and 2
        local numRareItems = 1 + (rand() % 2);

        //Determine number of common items: minimum 4
        local numCommonItems = 4 + (rand() % (filledSlots - numRareItems - 3));

        //Ensure we don't exceed available filled slots
        if(numCommonItems + numRareItems > filledSlots){
            numCommonItems = filledSlots - numRareItems;
        }

        local itemsToPlace = [];
        local pricesToPlace = [];

        //Add rare items to list
        for(local i = 0; i < numRareItems; i++){
            local randomRareIdx = rand() % mRareItems_.len();
            local rarePrice = 100 + (rand() % 101);
            itemsToPlace.append(::Item(mRareItems_[randomRareIdx]));
            pricesToPlace.append(rarePrice);
        }

        //Add common items to list
        for(local i = 0; i < numCommonItems; i++){
            local randomCommonIdx = rand() % mCommonItems_.len();
            local commonPrice = 10 + (rand() % 16);
            itemsToPlace.append(::Item(mCommonItems_[randomCommonIdx]));
            pricesToPlace.append(commonPrice);
        }

        //Shuffle items and prices together
        for(local i = itemsToPlace.len() - 1; i > 0; i--){
            local randomIdx = rand() % (i + 1);
            local tempItem = itemsToPlace[i];
            local tempPrice = pricesToPlace[i];
            itemsToPlace[i] = itemsToPlace[randomIdx];
            pricesToPlace[i] = pricesToPlace[randomIdx];
            itemsToPlace[randomIdx] = tempItem;
            pricesToPlace[randomIdx] = tempPrice;
        }

        //Place items and prices at random positions
        local itemIdx = 0;
        for(local i = 0; i < itemsToPlace.len(); i++){
            local randomPos = rand() % totalSlots;
            while(items[randomPos] != null){
                randomPos = (randomPos + 1) % totalSlots;
            }
            items[randomPos] = itemsToPlace[i];
            prices[randomPos] = pricesToPlace[i];
        }

        return {
            "items": items,
            "prices": prices
        };
    }
};
