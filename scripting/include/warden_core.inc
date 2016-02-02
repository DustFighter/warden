#if defined WARDEN_CORE_INC
 #endinput
#endif
#define WARDEN_CORE_INC

public const char kWardenVersion[] = "1.0.0";

typedef Warden_MenuCallback = function void(int client, int item);

enum Warden_MenuCategory
{
	Warden_MenuCategoryDays, // Every item in this category qualifies as a day, usage is restricted.
	Warden_MenuCategoryGames,
	Warden_MenuCategoryOther,
};

/**
 * Add a new item to the main menu.
 *
 * @param name			Item display name.
 * @param category		Item category.
 * @param callback		Callback to when the item is selected.
 *
 * @return				Item id (-1 if the item could not be added).
 */
native int Warden_RegisterItem(const char[] name, Warden_MenuCategory category, Warden_MenuCallback callback);

/**
 * Remove an item from the main menu.
 *
 * @param item			Item id.
 *
 * @noreturn
 */
native void Warden_DeregisterItem(int item);

/**
 * Get the current warden.
 *
 * @return				Client index (-1 if no warden).
 */
native int GetWarden();

/**
 * Set the current warden.
 *
 * @param client		Client index;
 *
 * @noreturn
 */
native void SetWarden(int client);

/**
 * Called when someone becomes warden.
 *
 * @param client		Client index.
 *
 * @noreturn
 */
forward void OnWardenCreated(int client);

/**
 * Called when the current warden leaves his position.
 *
 * @param client		Client index.
 *
 * @noreturn
 */
forward void OnWardenRemoved(int client);

public SharedPlugin __pl_warden_core =
{
	name = "warden_core",
	file = "warden_core.smx",
#if defined REQUIRED_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRED_PLUGIN
public __pl_warden_core_SetNTVOptional()
{
	MarkNativeAsOptional("Warden_RegisterItem");
	MarkNativeAsOptional("Warden_DeregisterItem");
	MarkNativeAsOptional("SetWarden");
	MarkNativeAsOptional("GetWarden");
}
