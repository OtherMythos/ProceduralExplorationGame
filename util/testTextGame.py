#!/usr/bin/python3

import time
import random

inventory = []

'''
This is not an actual game but created to demonstrate how these sort of games played out.
'''

def getOptions():
    print("1. Explore")
    print("2. Inventory")
    print("3. Town")
    print("4. Exit")
    val = input("")

    return int(val)

def getCombatOptions():
    print("1. Fight")
    print("2. Inventory")
    print("3. Flee")
    val = input("")

    return int(val)

def processEncounter():
    print("Encountered Goblin")
    getCombatOptions()

def determineFoundItem():
    items = ["Broken sword", "Health potion", "Gold coins", "Cursed book", "Massive sword", None]
    item = random.choice(items)
    if item is None:
        processEncounter()
        return

    print("You found '%s'" % item)

    while True:
        print("Keep it (Y/N)?")
        val = input("").upper()
        if val == "Y":
            print("Kept the %s" % item)
            inventory.append(item)
            break
        elif val == "N":
            print("Scrapped the %s" % item)
            break
        else:
            print("Please enter either 'Y' or 'N'")
            continue


def exploreLogic():
    for i in range(1, 10):
        print(str(i) + "0% ...")
        time.sleep(0.1)

    determineFoundItem()

def printInventory():
    print("==Inventory==")
    for i in inventory:
        print(i)

def main():
    print("This is a text based game")

    while True:
        selected = getOptions()

        if selected == 1:
            exploreLogic()
        elif selected == 2:
            printInventory()
            continue
        elif selected == 3:
            continue
        elif selected == 4:
            return
        else:
            print("Unknown input")


if __name__ == "__main__":
    main()
