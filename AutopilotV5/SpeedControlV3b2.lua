mod = peripheral.find("modem"); --modem output setting, optional
mod.open(224);
rednet.open(peripheral.getName(mod)); --modem portal
s = peripheral.find("electric_motor");
g = peripheral.find("Create_RotationSpeedController")
if s ~= nil then
    function setEngineSpeed(spd)
        s.setSpeed(spd);
    end
elseif g ~= nil then
    function setEngineSpeed(spd)
        g.setTargetSpeed(spd);
    end
end
thr = -100; --throttle output
vtgt = 80; --Target Speed
vlbnd = 70; --Speed lower bound
vubnd = 85; --Speed upper bound
v0 = 0; --speed of the last iteration
brk = 0;
str = {};
LANDED = 0;
t = 0;
t0 = 0;

m = ship.getMass();
C3 = 3908;
C4 = 4466;
n3 = 16; --number of equiv sails
n4 = 14; --number of brake flaps
--config
cfg = io.open("config.lua","r");
if cfg == nil then
    cfg = io.open("config.lua", "w");
    cfg:write("total propeller sails = 16\n");
    cfg:write("total brake flap = 16\n");
    cfg:write("propeller constant = 3908\n");
    cfg:write("brake constant = 4466\n");
    cfg:write("computer id receive = -1");
    error("Config file generated, change the values to fit your aircraft");
end
config = {};
configNum = 0;
for line in io.lines("config.lua") do
    configNum = configNum + 1;
    line = string.gsub(line,"%a", "")
    line = string.gsub(line,"=", "")
    config[configNum] = tonumber(line);
end
n3 = config[1];
n4 = config[2];
C3 = config[3];
C4 = config[4];
commandComputerID = config[5];
coeft = m/(C3*n3);
coefb = m/(C4*n4);

while true do
t = os.clock();
T = t - t0;
t0 = t;
spd = ship.getVelocity();
v = math.sqrt(spd.x^2+spd.y^2+spd.z^2);
v = v*3.6;--ship speed
a = (v-v0)/T; --acceleration
v0 = v;
id,str = rednet.receive(nil,0.1);
if str ~= nil and id == commandComputerID then
LANDED = str[3];
vtgt = str[4];
end
dthr = coeft*(1.3*(v-vtgt)-((v-vtgt)^2*a/1600));  --PD
if dthr >16 then
    dthr = 16;
elseif dthr <-16 then
    dthr = -16
end
brk = 1.2*coefb*(v-vtgt)-((v-vtgt)^2*a/1200);  --brake analog
thr = thr + dthr;
if brk<0 then --set bound for brake
    brk = 0;
elseif brk>15 then
    brk = 15;
end
if LANDED == 1 then --landed mode
    thr = -12;
    brk = 15;
end
if redstone.getInput("left") == true then --airport mode
    thr = -56;
    brk = 10;
end
redstone.setAnalogOutput("right", brk);
if thr<-256 then --bound limit
thr = -256;
elseif thr>-12 then
thr = -12;
end
thr, rnd = math.modf(thr);
setEngineSpeed(thr)--s.setSpeed(thr);
sleep(0.35);
end
