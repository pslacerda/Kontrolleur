//credits: 
//Eric Pavey: http://www.akeric.com/blog/?p=1435
//Rikard Lundstedt: http://code.google.com/p/apwidgets/
//Daniel Sauter et al: http://code.google.com/p/ketai/

//todo
//- draw values at pointer
//- draw xypressure at pointer if no value present

//- send touches as tuio
//- settings page: display device IP, device port
//- support screen orientations
//- support radiobutton, XYPressure, color, string
//- multiple parameter pages (one per address-space)
//- ordering/layout of values
//- support spreads

PFont fontA, fontB;

HashMap<String, RemoteValue> FRemoteValues;  //key: osc-address
HashMap<Integer, Touch> FTouchedValues;      //key: remoteValueID
HashMap<Integer, Touch> FTouches;            //key: pointerID

int CBack = 77;;
int CSlider = 102;
int CText = 230;
int CSeparators = 0;
int CTouch = 154;
int CModifierPanelHeight = 100;
int GValueHeight = height - CModifierPanelHeight;
int GValueTop;
String FLocalIP;

void setup() 
{
  orientation(PORTRAIT);

  FRemoteValues = new HashMap<String, RemoteValue>();
  FTouchedValues = new HashMap<Integer, Touch>();
  FTouches = new HashMap<Integer, Touch>();
  
  fontA = loadFont("Verdana-24.vlw");
  fontB = loadFont("Verdana-48.vlw");
  
  initMenu();
  if (loadSettings())
  {
    initNetwork();
    reset();
  }
  else
    toggleMenu();

  //get device IP
  WifiManager wifi = (WifiManager) getSystemService(Context.WIFI_SERVICE);
  WifiInfo info = wifi.getConnectionInfo();
  FLocalIP = Formatter.formatIpAddress(info.getIpAddress());
  
  FSensorManager = new KetaiSensorManager(this);
  Orientation = new PVector();
  Acceleration = new PVector();
  MagneticField = new PVector();

  FSensorManager.start();
}

void draw() 
{
  background(CBack);  
  //text(FLocalIP, width - 300, height - 100);
  
  if (FMenuVisible)
  {
    drawMenu();
    return;
  }
  
  if (FShowModifier.isChecked())
  {
    //draw modifier
    int spalt = 5;
    int bW = (width - 3 * spalt) / 4;
    
    noStroke();
    float x = 0;
    String[] mods = {"/100", "/10", "*10", "*100"};
    for (int i = 0; i < 4; i++)
    {
      if (FModifierID == i)
        fill(CBack);
      else
        fill(CSlider);
      
      rect(x, 0, bW - spalt/2, CModifierPanelHeight);
      fill(CBack);
      textAlign(CENTER);
      textFont(fontA, 24);
      text(mods[i], x + bW/2, CModifierPanelHeight/2 + 5);
      
      x += bW + spalt;
    }
  }
    
  //draw values
  textFont(fontB, 48);
  synchronized(this)
  {
    for(String key: FRemoteValues.keySet())
    {
      RemoteValue rm = FRemoteValues.get(key);
      rm.paint();
    }
  }
  
  //draw value separators
  stroke(CSeparators);
  float y = GValueTop;
  for (int i = 0; i < FRemoteValues.size(); i++)
  {
    line(0, y, width, y);
    y += GValueHeight;
  }
 
  //draw touchpoints
  fill(CTouch);
  noStroke();
  synchronized(this)
  {
    for(Integer key: FTouches.keySet())
    {
      Touch t = FTouches.get(key);
      t.paint();
    }
  }
 
  //send sensors
  OscBundle bundle = new OscBundle();
  if (FSendAcceleration.isChecked())
    addAcceleration(bundle);
  if (FSendOrientation.isChecked())
    addOrientation(bundle);  
  if (FSendMagneticField.isChecked())
    addMagneticField(bundle);
  sendBundle(bundle);
}

void keyPressed()
{
  if (key == CODED)
  {
    if (keyCode == MENU)
    {
      toggleMenu();
    }
  }
}
