# Script by Johan Akerstrom
# http://cosmoskey.blogspot.nl/2010/09/get-certificate-chain-from-any-port.html
Function Get-CertificateChain {
param(
[string]$server=$(throw "Mandatory parameter -Server is missing."),
[int]$port=$(throw "Mandatory parameter -Port is missing."),
[switch]$ToBase64
)
$code=@"
using System;
using System.Collections;
using System.Net;
using System.Net.Security;
using System.Net.Sockets;
using System.Security.Authentication;
using System.Text;
using System.Security.Cryptography.X509Certificates;
using System.IO;
using System.Threading;
namespace CosmosKey.Powershell
{
  public class SslUtility
  {
    private static byte[] CertChain;
    private static object Lock = new object();
    private static Hashtable certificateErrors = new Hashtable();
    public static bool ValidateServerCertificate(
        object sender,
        X509Certificate certificate,
        X509Chain chain,
        SslPolicyErrors sslPolicyErrors)
    {
      byte[] data = certificate.Export(X509ContentType.Cert);
      lock (Lock)
      {
        CertChain = data;
        Monitor.Pulse(Lock);
      }
      return true;
    }
    public static byte[] GetCertificate(string serverName, int port)
    {
      TcpClient client = new TcpClient(serverName,port);
          SslStream sslStream = new SslStream(
          client.GetStream(),
          false,
          new RemoteCertificateValidationCallback (ValidateServerCertificate),
          null
        );
      try
      {
        lock (Lock)
        {
          sslStream.BeginAuthenticateAsClient(serverName,null,null);
          bool didTimeout = Monitor.Wait(Lock);
        }
      }
      finally
      {
        client.Close();
      }
      return CertChain;
    }
  }
}
"@
  Add-Type $code
  [byte[]]$certData = [CosmosKey.Powershell.SslUtility]::GetCertificate($server,$port)
  if($ToBase64){
    [convert]::ToBase64String($certData)
  } else {
    $cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.import($certData)
    $cert
  }
}

# Export chain
Get-CertificateChain -server google.nl -Port 443 -ToBase64 > c:\cert.cer

# run on cmdline
# Decode cert
#certutil -decode c:\cert.cer c:\foo.cer
# Import in java keystore
#keytool -import -trustcacerts -file c:\foo.cer -keystore "C:\Program Files\Java\jre1.8.0_92\lib\security\cacerts" -storepass changeit -alias "google"