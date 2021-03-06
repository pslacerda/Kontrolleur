import oscP5.*;
import netP5.*;

import android.content.Context;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.text.format.Formatter;

OscP5 FNetwork;
NetAddress FTargetNetAddress;
boolean FNetworkIsUp;

void initNetwork()
{
  if (FNetwork != null)
  {
    FNetworkIsUp = false;
    FNetwork.dispose();
  }    

  FNetwork = new OscP5(this, FLocalPort);
  
  String ip = FIPField.getText();
  int port = Integer.parseInt(FPortField.getText());
  FTargetNetAddress = new NetAddress(ip, port);
  
  FNetworkIsUp = true;
  //println("Target: " + ip + ":" + port);
}

void sendBundle(OscBundle bundle)
{
  //send bundle if it contains messages
  if (FNetworkIsUp && bundle.size() > 0)
  {
    bundle.setTimetag(bundle.now() + 10000);
    FNetwork.send(bundle, FTargetNetAddress);
  }
}

void oscEvent(OscMessage message) 
{
  //println("message: " + message.addrPattern());
  //only accept specific messages
  if (!((message.checkAddrPattern("/k/add")) 
  || (message.checkAddrPattern("/k/update"))
  || (message.checkAddrPattern("/k/remove"))))
    return;

  String address = message.get(0).stringValue();
  address = address.trim();
  String name = "";
  String type = "Slider";
  float defaultValue = 0;
  float minimum = 0;
  float maximum = 1;
  float stepsize = 0;
  float value = 0;
  
  //read arguments if tjis is an add or update message
  if (message.checkTypetag("sssfffff"))
  {
    //println("typetags?: " + address);
    name = message.get(1).stringValue();
    type = message.get(2).stringValue();
    defaultValue = message.get(3).floatValue();
    minimum = message.get(4).floatValue();
    maximum = message.get(5).floatValue();
    stepsize = message.get(6).floatValue();
    value = message.get(7).floatValue();
  }
   
  if (message.checkAddrPattern("/k/add")) 
  { 
    //println("contains?: " + address);
    if (!FRemoteValues.containsKey(address))
    {
      //println("adding: " + address);
      int id = FRemoteValues.size();
      addRemoteValue(type, id, address, name, defaultValue, minimum, maximum, stepsize, value);
    }
  }
  else if (message.checkAddrPattern("/k/update"))
  {
    RemoteValue rm = FRemoteValues.get(address);
    if (!rm.Type.equals(type))
    {
      int id = rm.ID;
      rm = null;
      addRemoteValue(type, id, address, name, defaultValue, minimum, maximum, stepsize, value);
    }
    else
    {
      rm.Name = name;
      rm.DefaultValue = defaultValue;
      rm.Minimum = minimum;
      rm.Maximum = maximum;
      rm.Value = value;
    }
  }   
  else if (message.checkAddrPattern("/k/remove"))
  {
    if (FRemoteValues.containsKey(address))
    {
      synchronized(this)
      {
        FRemoteValues.remove(address);
      }
      
      //update IDs of all remotevalues
      int i = 0;
      for(String key: FRemoteValues.keySet())
      {
        RemoteValue rm = (RemoteValue) FRemoteValues.get(key);
        rm.ID = i;
        i++;
      }
    }  
  }
    
  //recompute the values height
  GValueHeight = (height - GValueTop) / FRemoteValues.size();
}

void addRemoteValue(String type, int id, String address, String name, float defaultValue, float minimum, float maximum, float stepsize, float value)
{
  RemoteValue rm;
  if (type.equals("Bang"))
    rm = new RemoteBang(id, address, name, minimum, maximum, value); 
  else if (type.equals("Toggle"))
    rm = new RemoteToggle(id, address, name, defaultValue, minimum, maximum, value); 
  else if (type.equals("Slider"))
    rm = new RemoteSlider(id, address, name, defaultValue, minimum, maximum, stepsize, value);
  else //if (type.equals("Endless"))
    rm = new RemoteEndless(id, address, name, defaultValue, minimum, maximum, stepsize, value); 

  rm.Type = type;
  synchronized(this)
  {
    FRemoteValues.put(address, rm);
  }
}

//ripped of: http://www.droidnova.com/get-the-ip-address-of-your-device,304.html
//seems to be the only working way to get the IP
String getLocalIP() 
{
  try 
  {
    WifiManager wifi = (WifiManager) getSystemService(Context.WIFI_SERVICE);
    WifiInfo info = wifi.getConnectionInfo();
    FLocalIP = Formatter.formatIpAddress(info.getIpAddress());
    return FLocalIP;
  } 
  catch (Exception ex) 
  {}
  return CNoNetwork;
}

String getTargetIP()
{
  if (!FLocalIP.equals(CNoNetwork))
  {
    //split ip and replace last byte with 255 which makes a good default target IP
    String[] bytes;
    bytes = FLocalIP.split("\\.");
    return bytes[0] + "." + bytes[1] + "." + bytes[2] + ".255";
  }
  else
    return CNoNetwork;    
}
