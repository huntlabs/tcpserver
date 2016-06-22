import stdo = std.stdio;
import std.datetime;
import neton.client;
import collie.socket;
import neton.messagecoder;
import message;

void main()
{
    stdo.writeln("Edit source/app.d to start your project.");
    EventLoop loop = new EventLoop();
    MyClient client = new MyClient(loop);
    ushort port = cast(ushort)8094;
    stdo.writeln("port is  : ",port);
    client.setMessageDecoder(new MyDecode());
    client.heartbeatTimeOut(3).connect("127.0.0.1",port);
    
    loop.run();
}

class MyClient : Client!false
{
    this(EventLoop loop)
    {
        super(loop);
    }
    int i = 0;
protected:
    override void onMessage(Message msg)
    {
        switch(msg.type())
        {
            case MSGType.BEAT.stringof :
                {
                    BeatMessage mg = cast(BeatMessage)msg;
                    stdo.writeln("\nHeat beat : ", cast(string)mg.data);
                    return;
                }
            case MSGType.DATA.stringof :
                {
                    auto mmsg = cast(DataMessage)msg;
                    stdo.write(" \t\tMyMessage IS : ", mmsg.fvalue);
                    switch (mmsg.commod)
                    {
                        case 0:
                            stdo.write(" + ");
                            break;
                        case 1:
                            stdo.write(" - ");
                            break;
                        case 2:
                            stdo.write(" *");
                            break;
                        case 3:
                            stdo.write(" / ");
                            break;
                        default:
                            stdo.write(" ? ");
                            break;
                    }
                    
                    stdo.writeln(mmsg.svalue, "  =  ", mmsg.value);
                    if(i > 5)
                        disconnect();
                }
                break;
            default:
                return ;
        }
    }
    
    override void onTimeOut()
    {
        stdo.writeln("timeOut : senf heartbeatTimeOut");
        auto mg = new BeatMessage();
        mg.data = cast(ubyte[])"client";
        send(mg);
        
        ++i;
        
        DataMessage mmsg = new DataMessage();
        long tm = Clock.currStdTime();
        mmsg.commod = cast(uint)(tm % 4);
        mmsg.fvalue = tm  / 50;
        mmsg.svalue = tm  / 300;
        send(mmsg); 
    }
    override void onConnect()
    {
        stdo.writeln("connecd!");
       
       
        DataMessage mmsg = new DataMessage();
        long tm = Clock.currStdTime();
        mmsg.commod = cast(uint)(tm % 4);
        mmsg.fvalue = tm  / 50;
        mmsg.svalue = tm  / 300;
        send(mmsg);
    }
    
    override void onDisConnect()
    {
        stdo.writeln("unactive!");
        eventLoop().stop();
    }
}
