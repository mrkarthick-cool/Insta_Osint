# Insta_Osint
     
     Gather publicly available information from Instagram profiles to analyze connections  activities  and trends  Useful for cybersecurity research investigations and digital footprint analysis


_________________________________________________________________________________________

   # Step-by-step installation & run (Debian/Ubuntu /kali / parrot)

_________________________________________________________________________________________


          # Update the system packages


      sudo apt-get update      
     sudo apt-get upgrade -y  


# Clone the repo


      git clone https://github.com/mrkarthick-cool/Insta_Osint.git && clear



# Change Dir and  give permission 


       cd Insta_Osint &&  chmod +x *

# Important:replace mr_rkarthik with the Instagram username you want to scan.

  > run code 

        ./Insta_osint.shmr_rkarthik


# If you want to scan a different username, run:

      ./Insta_osint.sh target_username_here


# Start the local server to view results in your browser

      ./Local_Server.sh


# This script usually prints which port it’s listening on (e.g. Serving at http://0.0.0.0:8080).

If it does not, find the local IP and open the browser manually:

Find your machine’s local IP:

     hostname -I    # prints IP(s), e.g. 192.168.1.12


# Construct the URL using the printed port (replace PORT with the port shown by the server):

     http://192.168.1.12:PORT


Or try the loopback:

      http://127.0.0.1:PORT


Copy the localhost/local IP into Chrome/Firefox address bar

     Paste the URL from step 5 (e.g. http://127.0.0.1:8080 or http://192.168.1.12:8080) and press Enter

_____________________________________________________________________________________________________________________


# Disclaimer: Insta_Osint is intended solely for legitimate cybersecurity research, penetration testing with permission, and educational use. The author is not responsible for misuse.

     # Thanks for using the tool — please share and credit responsibly.

