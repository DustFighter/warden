#if defined WARDEN_CORE_INC
 #endinput
#endif
#define WARDEN_CORE_INC

public const char kWardenVersion[] = "1.0.0";

typedef Warden_MenuCallback = function void(int client, const char[] info);

enum Warden_MenuCategory
{
	Warden_MenuCategoryDays, // Every item in this category qualifies as a day, usage is restricted.
	Warden_MenuCategoryGames,
	Warden_MenuCategoryOther,
};

/**
 * Add a new item to the main menu.
 *
 * @param info			Info string passed in the callback.
 * @param display		Item name in the menu.
 * @param category		Item category.
 * @param callback		Callback to when the item is selected.
 *
 * @return				Item id (-1 if the item could not be added).
 */
native int Warden_RegisterItem(const char[] info, const char[] display, Warden_MenuCategory category, Warden_MenuCallback callback);

/**
 * Remove an item from the main menu.
 *
 * @param item			Item id.
 *
 * @noreturn
 */
native void Warden_DeregisterItem(int item);

/**
 * Retrieve the id of an item given the item display name and category.
 *
 * @param display		Item display name.
 * @param category		Item category.
 *
 * @return				Item id (-1 if the item was not found).
 */
native int Warden_FindItem(const char[] display, Warden_MenuCategory category);

/**
 * Get the current warden.
 *
 * @return				Client index (-1 if no warden).
 */
native int Warden_Get();

/**
 * Set the current warden.
 *
 * @param client		Client index;
 *
 * @noreturn
 */
native void Warden_Set(int client);

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
	MarkNativeAsOptional("Warden_FindItem");
	MarkNativeAsOptional("Warden_Set");
	MarkNativeAsOptional("Warden_Get");
}
