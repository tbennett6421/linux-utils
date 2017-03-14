/* To compile normally
 *       gcc -Wall netset.c -o netset
 *
 * To compile with debugging info
 *       gcc -g -Wall netset.c -o netset
 */

/* Initial configuration
 *   - setup a working copy of INTERFACES_PATH that has NETDEV setup for dhcp
 *   - copy it to the location DHCP_CONFIG
 */

/* To add a new profile, do the following,
 *
 * after line  59 - add a name for the profile to be
 * copy, paste and edit an else if group in interfaceLoad() to reflect a new profile
 *
 */

/* Most interface options exec the following
 * ifconfig netdevice xxx.xxx.xxx.xxx/yy
 * ifconfig netdevice down
 * ifconfig netdevice up
 */

// I suggest creating a hidden netset folder

#include<stdio.h>
#include<stdlib.h>
#include<string.h>

#define BUFFER 1024
#define SUCCESS 0
#define ERR_USAGE -1
#define ERR_UNSUPPORTED_PROFILE -2
#define ERR_MALLOC_FAILURE -100
#define ERR_FOPEN_FAILURE -200

// Prototypes
int interfaceLoad(char *profile)
int setStatic(char *profile, char *dev_addr);
int writeConky(char *conky_profile, char *cpe_addr, char *username, char *password);

//------------------------------------
//-- Global Configuration options
//------------------------------------
static const char CONKY_FILEPATH[]  = "/home/world/.netset/interface";
static const char DHCP_CONFIG[]     = "/home/world/.netset/dhcp";
static const char INTERFACES_PATH[] = "/etc/network/interfaces";
static const char RESTART_NETWORK[] = "/etc/init.d/networking restart";
static const char NETDEV[] = "eth1";
int DO_CONKY = 1;    // 1 to write info to file || 0 to not do it

//character strings for comparing
char *dhcp = "dhcp";
char *three = "365";
char *buffalo = "buffalo";
char *kc = "kc";
char *sonicwall = "sonicwall";
char *visionnet = "visionnet";

int main(int argc, char **argv){
    
	if(argc != 2){
		printf("\n");
        printf("USAGE: %s <profile name>\n", argv[0]);
        printf("(must be run with sudo)\n\n");
        
		printf("profile names include \n");
        printf("dhcp \n");
        printf("365\n");
        printf("buffalo\n");
        printf("kc\n");
        printf("sonicwall\n");
        printf("visionnet\n");
        printf("\n");
		return ERR_USAGE;
    }
    
	int retcode = interfaceLoad(argv[1]);
    if(retcode < 0){
        printf("Looks like an error occured that may have prevented the program from succeeding\n");
        printf("return code was %d\n", retcode);
    }
    return retcode;
} // End main

//strcmp returns 0 if strings are equal so
//the logic reads as if the two strings are equal
int interfaceLoad(char *profile)
{

    if(strcmp (profile, three) == 0){
        
        // profile options
        char profile[] = "3650MHz";
        char dev_addr[] = "192.168.254.252/24";
        
        // conky options
        char conky_profile[] = "3650MHz (Wimax)";
        char username[] = "Operator";
        char password[] = "wimax";
        char cpe_addr[] = "192.168.254.251";
        
        //do statics
        setStatic(profile, dev_addr);
        
        //do conky
        if (DO_CONKY) {
            writeConky(conky_profile, cpe_addr, username, password);
        }
	}

    else if(strcmp (profile, buffalo) == 0){
        
        // profile options
        char profile[] = "Buffalo";
        char dev_addr[] = "192.168.11.5/24";
        
        // conky options
        char conky_profile[] = "Buffalo";
        char username[] = "root";
        char password[] = "password";
        char cpe_addr[] = "192.168.11.1";
        
        //do statics
        setStatic(profile, dev_addr);
        
        //do conky
        if (DO_CONKY) {
            writeConky(conky_profile, cpe_addr, username, password);
        }
	}

	else if(strcmp (profile, kc) == 0){
        
        // profile options
        char profile[] = "Kingdom City Radio";
        char dev_addr[] = "192.168.254.252/24";
        
        // conky options
        char conky_profile[] = "3650MHz (Kingdom City)";
        char username[] = "installer";
        char password[] = "installer";
        char cpe_addr[] = "192.168.254.251";
        
        //do statics
        setStatic(profile, dev_addr);
        
        //do conky
        if (DO_CONKY) {
            writeConky(conky_profile, cpe_addr, username, password);
        }
	}

    else if(strcmp (profile, sonicwall) == 0){
        
        // profile options
        char profile[] = "SonicWall";
        char dev_addr[] = "192.168.168.168/24";
        
        // conky options
        char conky_profile[] = "SonicWall";
        char username[] = "admin";
        char password[] = "password";
        char cpe_addr[] = "192.168.168.168";
        
        //do statics
        setStatic(profile, dev_addr);
        
        //do conky
        if (DO_CONKY) {
            writeConky(conky_profile, cpe_addr, username, password);
        }
	}
    
    else if(strcmp (profile, visionnet) == 0){
        
        // profile options
        char profile[] = "VisionNet";
        char dev_addr[] = "192.168.1.5/24";
        
        // conky options
        char conky_profile[] = "VisionNet";
        char username[] = "admin";
        char password[] = "0123456789";
        char cpe_addr[] = "192.168.1.254";
        
        //do statics
        setStatic(profile, dev_addr);
        
        //do conky
        if (DO_CONKY) {
            writeConky(conky_profile, cpe_addr, username, password);
        }
	}
    
    else if(strcmp (profile, dhcp) == 0)
	{
        //add in warnings
        //  - loss of network
        //  - do dhcp initial setup
        
        char *com_backupConfig = NULL;
        char *com_cpDHCPConfig = NULL;
        char *com_restartNetwork = NULL;
        char *com_devDown = NULL;
        char *com_devUp = NULL;
        char *buf = NULL;
        int len;
		
        // Setup buffer
        buf = malloc(sizeof(char) * BUFFER + 1);
        if(buf == NULL){
            printf("Unable to allocate memory to work with\n");
            return ERR_MALLOC_FAILURE;
        }
        
        // Compose command to backup old interface
        sprintf(buf, "mv %s %s.old", INTERFACES_PATH,INTERFACES_PATH);
        len = strlen(buf);
        com_backupConfig = malloc(sizeof(char) * len + 1);
        strcpy(com_backupConfig, buf);
        
        // Compose command to bring in dhcp config
        sprintf(buf, "cp %s %s", DHCP_CONFIG, INTERFACES_PATH);
        len = strlen(buf);
        com_cpDHCPConfig = malloc(sizeof(char) * len + 1);
        strcpy(com_cpDHCPConfig, buf);
        
        // Compose command to restart network
        sprintf(buf, "%s", RESTART_NETWORK);
        len = strlen(buf);
        com_restartNetwork = malloc(sizeof(char) * len + 1);
        strcpy(com_restartNetwork, buf);
        
        // Compose command to bring device down
        sprintf(buf, "ifconfig %s down", NETDEV);
        len = strlen(buf);
        com_devDown = malloc(sizeof(char) * len + 1);
        strcpy(com_devDown, buf);
        
        // Compose command to bring device up
        sprintf(buf, "ifconfig %s up", NETDEV);
        len = strlen(buf);
        com_devUp = malloc(sizeof(char) * len + 1);
        strcpy(com_devUp, buf);
        
        // Do commands
        printf("\n\n");
        printf("DHCP Selected:\n");
        
        printf("Moving %s to %s.old\n", INTERFACES_PATH, INTERFACES_PATH);
        system(com_backupConfig);
        
        printf("Copying %s to %s\n", DHCP_CONFIG, INTERFACES_PATH);
        system(com_cpDHCPConfig);
        
        printf("Restarting network: (%s\n", RESTART_NETWORK);
        system(com_restartNetwork);
        
        printf("Bringing %s down\n", NETDEV);
        system(com_devDown);
        
        printf("Bringing %s up\n", NETDEV);
        system(com_devUp);
        if (DO_CONKY) {
            writeConky("DHCP", "N/A", "N/A", "N/A");
        }        
	}//end if x - dhcp
    
	else{
		printf("Unsupported profile at this time!\n");
        return ERR_UNSUPPORTED_PROFILE;
    }
    
    return SUCCESS;
}//end interfaceLoad

int setStatic(char *profile, char *dev_addr){
    //needed variables
    int len = 0;
    char *buf = NULL;
    char *com_setAddr = NULL;
    char *com_devDown = NULL;
    char *com_devUp = NULL;

    printf("%s Selected:\n", profile);
    
    // Setup buffer
    buf = malloc(sizeof(char) * BUFFER + 1);
    if(buf == NULL){
        printf("Unable to allocate memory to work with\n");
        return ERR_MALLOC_FAILURE;
    }
    
    // Compose command to set address
    sprintf(buf, "ifconfig %s %s", NETDEV, dev_addr);
    len = strlen(buf);
    com_setAddr = malloc(sizeof(char) * len + 1);
    strcpy(com_setAddr, buf);
    
    // Compose command to bring device down
    sprintf(buf, "ifconfig %s down", NETDEV);
    len = strlen(buf);
    com_devDown = malloc(sizeof(char) * len + 1);
    strcpy(com_devDown, buf);
    
    // Compose command to bring device up
    sprintf(buf, "ifconfig %s up", NETDEV);
    len = strlen(buf);
    com_devUp = malloc(sizeof(char) * len + 1);
    strcpy(com_devUp, buf);
    
    // Exec commands
    printf("Setting %s to %s\n", NETDEV, dev_addr);
    system(com_setAddr);
    
    printf("Bringing %s down\n", NETDEV);
    system(com_devDown);
    
    printf("Bringing %s up\n", NETDEV);
    system(com_devUp);
    return SUCCESS;
    
}//end setStatic

int writeConky(char *conky_profile, char *cpe_addr, char *username, char *password){

    FILE *finterface;
    finterface = fopen(CONKY_FILEPATH, "w");
    if(finterface == NULL){
        printf("Unable to open %s for writing\n", CONKY_FILEPATH);
        return ERR_FOPEN_FAILURE;
    }
    fprintf(finterface, "%s\n", conky_profile);
    fprintf(finterface, "%s\n", cpe_addr);
    fprintf(finterface, "%s\n", username);
    fprintf(finterface, "%s\n", password);
    fclose(finterface);
    return SUCCESS;
}
