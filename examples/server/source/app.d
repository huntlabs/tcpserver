import std.stdio;
import std.functional;
import std.datetime;
import std.variant;

import collie.socket.eventloopgroup;
import neton.server;
import neton.messagecoder;
import message;

alias NetServer = Server!false;
alias NetContext = NetServer.Contex;

void main()
{
    auto server = new NetServer();
    server.setCallBack(toDelegate(&handle));
    server.heartbeatTimeOut(120).bind(8094);
    server.setMessageDcoder(new MyDecode());
    server.group(new EventLoopGroup());
    server.run();
}

void handle(NetContext ctx,Message msg )
{
    switch(msg.type())
    {
        case "TimeOut" : 
            writeln("Time out !@!!");
            ctx.close();
            break;
        case "TransportActive" :
            {
            writeln("new connect start.");
            Variant tmp = Clock.currTime();
            ctx.setData(tmp);
            }
            break;
        case "TransportInActive" :
            {
            auto date = ctx.data.get!SysTime();
            writeln("connect closed!, the connect time is : ",date);
            }
            break;
        case MSGType.DATA.stringof :
            handleData(forward!(ctx,msg));
            break;
        case MSGType.BEAT.stringof :
            handleBeat(forward!(ctx,msg));
            break;
        default :
            writeln("Unknow Message Type will close the link!");
            ctx.close();
            break;
    }
}


void handleData(NetContext ctx,Message msg )
{
    DataMessage mmsg = cast(DataMessage)msg;
    if(mmsg is null)
    {
        writeln("data erro close");
        ctx.close();
    }
    write(" \t\tMyMessage IS : ", mmsg.fvalue);
    switch (mmsg.commod)
    {
        case 0:
            mmsg.value = mmsg.fvalue + mmsg.svalue;
            write(" + ");
            break;
        case 1:
            mmsg.value = mmsg.fvalue - mmsg.svalue;
            write(" - ");
            break;
        case 2:
            mmsg.value = mmsg.fvalue * mmsg.svalue;
            write(" * ");
            break;
        case 3:
            mmsg.value = mmsg.fvalue / mmsg.svalue;
            write(" / ");
            break;
        default:
            mmsg.value = mmsg.fvalue;
            write(" ? ");
            break;
    }
    writeln(mmsg.svalue, "  =  ", mmsg.value);
    ctx.write(mmsg);
}

void handleBeat(NetContext ctx,Message msg)
{
    BeatMessage mmsg = cast(BeatMessage)msg;
    writeln("\nHeatbeat: data : " , cast(string)mmsg.data);
    mmsg.data = cast(ubyte[])"server";
    ctx.write(mmsg);
}

