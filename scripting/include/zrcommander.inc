#if defined _zrcommander_included
  #endinput
#endif
#define _zrcommander_included

/**
 * Checks if any commander exist
 *
 * @true on match , false if not
 */
native bool zrc_exist();

/**
 * returns if client is commander
 *
 * @param client		The client to run the check on
 * @true on match, false if not		
 *********************************************************/
native bool zrc_is(client);

/**
 * Set a client as commander
 *
 * @param client		The client to set as commander
 * @NoReturn
 */
native int zrc_set(client);

/**
 * Removes the current commander if he exists
 *
 * @param client		The commander client to remove
 * @NoReturn	
 */
native int zrc_remove(client);

/**
 * Called when a commander has been created.
 *
 * @param client            Client that has been commander.	       
 */
forward void zrc_OnCommanderCreated(client); 

/**
 * Called when a player is about to be commander.
 *
 * @param client            Client index.	  
 * @return		Plugin_Changed to apply new values, Plugin_Continue to allow as is and >= Plugin_Handled to block 
 */
forward Action zrc_OnCommanderCreate(client); 

/**
 * Called when a commander left the commander position.
 *
 * @param client            Client index.	       
 */
forward void zrc_OnCommanderLeft(client); 