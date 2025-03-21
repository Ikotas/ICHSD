########################################################################
# ICHSD - Clean up the Hardsub Sources for Decimation v1.0
# 2025.3.21 Created by Ikotas
########################################################################
# Syntax and Parameters
# ICHSD(clip input, int "cr", float "ythresh", int "mthresh",
#        bool "manual", int "cr1f", int "cr1t",
#        int "cr2f", int "cr2t", int "cr3f", int "cr3t",
#        int "cr4f", int "cr4t", int "cr5f", int "cr5t",
#        bool "show", int "ml", bool "ulp", int "suby")
########################################################################

function ICHSD(clip input, int "cr", float "ythresh", int "mthresh", bool "manual",\
 int "cr1f", int "cr1t", int "cr2f", int "cr2t", int "cr3f", int "cr3t",\
 int "cr4f", int "cr4t", int "cr5f", int "cr5t", bool "show", int "ml", bool "ulp", int "suby") {

    global icr       = default(cr,         1)
    global ythresh   = default(ythresh, 20.0)
    global mthresh   = default(mthresh, 2000)
    global anticombs = default(manual, false)
    global cr1f      = default(cr1f,       0)
    global cr1t      = default(cr1t,       0)
    global cr2f      = default(cr2f,       0)
    global cr2t      = default(cr2t,       0)
    global cr3f      = default(cr3f,       0)
    global cr3t      = default(cr3t,       0)
    global cr4f      = default(cr4f,       0)
    global cr4t      = default(cr4t,       0)
    global cr5f      = default(cr5f,       0)
    global cr5t      = default(cr5t,       0)
    global showinfo  = default(show,   false)
    global ml        = default(ml,        21)
    global ulpflag   = default(ulp,     true)
    global suby      = default(suby,       0)

    global base0=input.TFM(mode=2,pp=1,slow=2,micmatching=2,mmsco=false,metric=1,blockx=64,blocky=64)
    global ovrc=input.TFM(mode=0,pp=1,blockx=64,blocky=64,ovr="C:\AviSynth\ICHSD\ovrc.txt") # Need to change to correct PATH
    global ovrp=input.TFM(mode=0,pp=1,blockx=64,blocky=64,ovr="C:\AviSynth\ICHSD\ovrp.txt") # Need to change to correct PATH
    global deint=input.TFM(mode=0,pp=3,cthresh=-1)

    global deintc=input.TFM(mode=0,pp=3,cthresh=-1,ovr="C:\AviSynth\ICHSD\ovrc.txt") # Need to change to correct PATH
    global deintp=input.TFM(mode=0,pp=3,cthresh=-1,ovr="C:\AviSynth\ICHSD\ovrp.txt") # Need to change to correct PATH

    global crovrc=ovrc.CombReduce(left=0,right=0,mode=(icr==0?1:icr))
    global crovrp=ovrp.CombReduce(left=0,right=0,mode=(icr==0?1:icr))

    Import("C:\AviSynth\ICHSD\ICHSD_patternlist.txt") # Need to change to correct PATH

# Processing Match u & Base preparation

    u2cp=ConditionalFilter(base0,ovrc,ovrp,"""
        mc=StrLen(String(propGetInt(ovrc,"TFMMics",index=1)))
        mp=StrLen(String(propGetInt(ovrp,"TFMMics",index=0)))
        Abs(mc-mp)>=2&&mp==4
        ""","=","true")
    global base=ConditionalFilter(base0,u2cp,base0,"""propGetInt("TFMMatch")""","=","4")

    global baseprev=base.Loop(2,0,-1).Trim(0,FrameCount(input)-1)

# Processing

    # Manual handling of remaining combs
    promanualcr=ConditionalFilter(base,deintp,icr==0?deintp:(icr==1||icr==2)==true?crovrp:ovrp,"""
        (cr1f>0&&current_frame>=cr1f&&cr1t>0&&current_frame<=cr1t)\
        ||(cr2f>0&&current_frame>=cr2f&&cr2t>0&&current_frame<=cr2t)\
        ||(cr3f>0&&current_frame>=cr3f&&cr3t>0&&current_frame<=cr3t)\
        ||(cr4f>0&&current_frame>=cr4f&&cr4t>0&&current_frame<=cr4t)\
        ||(cr5f>0&&current_frame>=cr5f&&cr5t>0&&current_frame<=cr5t)
        ""","=","true")

    promanualprev=ConditionalFilter(baseprev,deintc.Loop(2,0,-1).Trim(0,FrameCount(base)-1),baseprev,"""
        (cr1f>0&&current_frame-1>=cr1f&&cr1t>0&&current_frame-1<=cr1t)\
        ||(cr2f>0&&current_frame-1>=cr2f&&cr2t>0&&current_frame-1<=cr2t)\
        ||(cr3f>0&&current_frame-1>=cr3f&&cr3t>0&&current_frame-1<=cr3t)\
        ||(cr4f>0&&current_frame-1>=cr4f&&cr4t>0&&current_frame-1<=cr4t)\
        ||(cr5f>0&&current_frame-1>=cr5f&&cr5t>0&&current_frame-1<=cr5t)
        ""","=","true")

    promanualp=ConditionalFilter(base,deintp,ovrp,"""
        (cr1f>0&&current_frame>=cr1f&&cr1t>0&&current_frame<=cr1t)\
        ||(cr2f>0&&current_frame>=cr2f&&cr2t>0&&current_frame<=cr2t)\
        ||(cr3f>0&&current_frame>=cr3f&&cr3t>0&&current_frame<=cr3t)\
        ||(cr4f>0&&current_frame>=cr4f&&cr4t>0&&current_frame<=cr4t)\
        ||(cr5f>0&&current_frame>=cr5f&&cr5t>0&&current_frame<=cr5t)
        ""","=","true")

    promanualc=ConditionalFilter(base,deintc,ovrc,"""
        (cr1f>0&&current_frame>=cr1f&&cr1t>0&&current_frame<=cr1t)\
        ||(cr2f>0&&current_frame>=cr2f&&cr2t>0&&current_frame<=cr2t)\
        ||(cr3f>0&&current_frame>=cr3f&&cr3t>0&&current_frame<=cr3t)\
        ||(cr4f>0&&current_frame>=cr4f&&cr4t>0&&current_frame<=cr4t)\
        ||(cr5f>0&&current_frame>=cr5f&&cr5t>0&&current_frame<=cr5t)
        ""","=","true")

    # Handle back side p
    procpx3=ConditionalFilter(base\
        ,icr==0?deintp:crovrp\
        ,anticombs==true?promanualcr:icr==0?deintp:(icr==1||icr==2)==true?crovrp:ovrp,"""
            LumaDifference(ovrc,crovrc)>0&&LumaDifference(ovrp,crovrp)>0
            ""","=","true")
    procpx2=ConditionalFilter(base,deintp,procpx3,"""propGetInt(ovrp,"TFMMics",index=0)""",">","mthresh")#,show=true)
    procpx=ConditionalFilter(deint,procpx2,procpx3,"YDifferenceFromPrevious()",">","ythresh")#,show=true)

    # Handle front side p
    proxpc3=ConditionalFilter(base\
        ,icr==0?deintc.Loop(2,0,-1).Trim(0,FrameCount(base)-1):crovrc.Loop(2,0,-1).Trim(0,FrameCount(base)-1)\
        ,anticombs==true?promanualprev:baseprev,"""
        LumaDifference(ovrc.Loop(2,0,-1).Trim(0,FrameCount(base)-1),crovrc.Loop(2,0,-1).Trim(0,FrameCount(base)-1))>0\
        &&LumaDifference(ovrp.Loop(2,0,-1).Trim(0,FrameCount(base)-1),crovrp.Loop(2,0,-1).Trim(0,FrameCount(base)-1))>0
        ""","=","true")
    proxpc2=ConditionalFilter(base,deintp,proxpc3,"""propGetInt(ovrp,"TFMMics",index=0)""",">","mthresh")#,show=true)
    proxpc=ConditionalFilter(deint,proxpc2,proxpc3,"YDifferenceFromPrevious()",">","ythresh")#,show=true)

    # Handle other p
    proxpx3=ConditionalFilter(base\
        ,icr==0?deintp:crovrp\
        ,anticombs==true?promanualp:ovrp,"""
            LumaDifference(ovrc,crovrc)>0&&LumaDifference(ovrp,crovrp)>0
            ""","=","true")
    proxpx2=ConditionalFilter(base,deintp,proxpx3,"""propGetInt(ovrp,"TFMMics",index=0)""",">","mthresh")#,show=true)
    proxpx=ConditionalFilter(deint,proxpx2,proxpx3,"YDifferenceFromPrevious()",">","ythresh")#,show=true)

    # Handle c
    proxcx3=ConditionalFilter(base\
        ,icr==0?deintc:crovrc\
        ,anticombs==true?promanualc:ovrc,"""
            LumaDifference(ovrc,crovrc)>0&&LumaDifference(ovrp,crovrp)>0
            ""","=","true")
    proxcx2=ConditionalFilter(base,deintc,proxcx3,"""propGetInt(ovrc,"TFMMics",index=1)""",">","mthresh")#,show=true)
    proxcx=ConditionalFilter(deint,proxcx2,proxcx3,"YDifferenceFromPrevious()",">","ythresh")#,show=true)

# Checking p

    # Scope to be checked *X <-Current p
    #
    # 12 <-        0     ->  9
    # 210432104321 0 123401234
    # ppcccppcccpp[X]ccppcccpp

    chkpn5ppx=ConditionalFilter(base,proxcx,proxpx,"""
        bm12=propGetInt(base,"TFMMatch",offset=-12)+propGetInt(base,"TFMMatch",offset=-11)
        bm7=propGetInt(base,"TFMMatch",offset=-7)+propGetInt(base,"TFMMatch",offset=-6)
        b3=propGetInt("TFMMatch",offset=3)+propGetInt("TFMMatch",offset=4)
        b8=propGetInt("TFMMatch",offset=8)+propGetInt("TFMMatch",offset=9)
        (((bm12==0&&current_frame>12)||(bm7==0&&current_frame>7))\
        &&((b3==0&&current_frame<FrameCount()-5)||(b8==0&&current_frame<FrameCount()-10)))\
        ||(bm12==0&&current_frame>12&&LumaDifference(base,base.Loop(13,0,-1).Trim(0,FrameCount()-1))<ythresh\
        &&bm7==0&&current_frame>7&&LumaDifference(base,base.Loop(8,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(b3==0&&current_frame<FrameCount()-5&&LumaDifference(base,base.Trim(3,0).Loop(4,FrameCount()-1,-1))<ythresh\
        &&b8==0&&current_frame<FrameCount()-10&&LumaDifference(base,base.Trim(8,0).Loop(4,FrameCount()-1,-1))<ythresh)
        ""","=","true")

    # Scope to be checked *X <-Current p
    #
    # 31 <-                           0                          -> 30
    # 1043210432104321043210432104321 0 123401234012340123401234012340
    # ppcccppcccppcccppcccppcccppcccp[X]cccppcccppcccppcccppcccppcccpp

    chkpn5cxc2=ConditionalFilter(base,procpx,proxpx,"""
        bm30=propGetInt(base,"TFMMatch",offset=-31)+propGetInt(base,"TFMMatch",offset=-30)
        bm25=propGetInt(base,"TFMMatch",offset=-26)+propGetInt(base,"TFMMatch",offset=-25)
        bm20=propGetInt(base,"TFMMatch",offset=-21)+propGetInt(base,"TFMMatch",offset=-20)
        bm15=propGetInt(base,"TFMMatch",offset=-16)+propGetInt(base,"TFMMatch",offset=-15)
        bm10=propGetInt(base,"TFMMatch",offset=-11)+propGetInt(base,"TFMMatch",offset=-10)
        bm5=propGetInt(base,"TFMMatch",offset=-6)+propGetInt(base,"TFMMatch",offset=-5)
        b5=propGetInt("TFMMatch",offset=4)+propGetInt("TFMMatch",offset=5)
        b10=propGetInt("TFMMatch",offset=9)+propGetInt("TFMMatch",offset=10)
        b15=propGetInt("TFMMatch",offset=14)+propGetInt("TFMMatch",offset=15)
        b20=propGetInt("TFMMatch",offset=19)+propGetInt("TFMMatch",offset=20)
        b25=propGetInt("TFMMatch",offset=24)+propGetInt("TFMMatch",offset=25)
        b30=propGetInt("TFMMatch",offset=29)+propGetInt("TFMMatch",offset=30)
        (((bm30==0&&current_frame>31)||(bm25==0&&current_frame>26)||(bm20==0&&current_frame>21)\
        ||(bm15==0&&current_frame>16)||(bm10==0&&current_frame>11)||(bm5==0&&current_frame>6))\
        &&((b5==0&&current_frame<FrameCount()-6)||(b10==0&&current_frame<FrameCount()-11)\
        ||(b15==0&&current_frame<FrameCount()-16)||(b20==0&&current_frame<FrameCount()-21)\
        ||(b25==0&&current_frame<FrameCount()-26)||(b30==0&&current_frame<FrameCount()-31)))\
        ||(bm20==0&&current_frame>21&&bm15==0&&current_frame>16)\
        ||(bm20==0&&current_frame>21&&bm10==0&&current_frame>11)\
        ||(bm20==0&&current_frame>21&&bm5==0&&current_frame>6)\
        ||(bm15==0&&current_frame>16&&bm10==0&&current_frame>11)\
        ||(bm15==0&&current_frame>16&&bm5==0&&current_frame>6)\
        ||(bm10==0&&current_frame>11&&bm5==0&&current_frame>6)\
        ||(b5==0&&current_frame<FrameCount()-6&&b10==0&&current_frame<FrameCount()-11)\
        ||(b5==0&&current_frame<FrameCount()-6&&b15==0&&current_frame<FrameCount()-16)\
        ||(b5==0&&current_frame<FrameCount()-6&&b20==0&&current_frame<FrameCount()-21)\
        ||(b10==0&&current_frame<FrameCount()-11&&b15==0&&current_frame<FrameCount()-16)\
        ||(b10==0&&current_frame<FrameCount()-11&&b20==0&&current_frame<FrameCount()-21)\
        ||(b15==0&&current_frame<FrameCount()-16&&b20==0&&current_frame<FrameCount()-21)
        ""","=","true")
    chkpn5cxc=ConditionalFilter(base,proxpc,chkpn5cxc2,"""
        bm30=propGetInt(base,"TFMMatch",offset=-30)+propGetInt(base,"TFMMatch",offset=-29)
        bm25=propGetInt(base,"TFMMatch",offset=-25)+propGetInt(base,"TFMMatch",offset=-24)
        bm20=propGetInt(base,"TFMMatch",offset=-20)+propGetInt(base,"TFMMatch",offset=-19)
        bm15=propGetInt(base,"TFMMatch",offset=-15)+propGetInt(base,"TFMMatch",offset=-14)
        bm10=propGetInt(base,"TFMMatch",offset=-10)+propGetInt(base,"TFMMatch",offset=-9)
        bm5=propGetInt(base,"TFMMatch",offset=-5)+propGetInt(base,"TFMMatch",offset=-4)
        b5=propGetInt("TFMMatch",offset=5)+propGetInt("TFMMatch",offset=6)
        b10=propGetInt("TFMMatch",offset=10)+propGetInt("TFMMatch",offset=11)
        b15=propGetInt("TFMMatch",offset=15)+propGetInt("TFMMatch",offset=16)
        b20=propGetInt("TFMMatch",offset=20)+propGetInt("TFMMatch",offset=21)
        b25=propGetInt("TFMMatch",offset=25)+propGetInt("TFMMatch",offset=26)
        b30=propGetInt("TFMMatch",offset=30)+propGetInt("TFMMatch",offset=31)
        (((bm30==0&&current_frame>30)||(bm25==0&&current_frame>25)||(bm20==0&&current_frame>20)\
        ||(bm15==0&&current_frame>15)||(bm10==0&&current_frame>10)||(bm5==0&&current_frame>5))\
        &&((b5==0&&current_frame<FrameCount()-7)||(b10==0&&current_frame<FrameCount()-12)\
        ||(b15==0&&current_frame<FrameCount()-17)||(b20==0&&current_frame<FrameCount()-22)\
        ||(b25==0&&current_frame<FrameCount()-27)||(b30==0&&current_frame<FrameCount()-32)))\
        ||(bm20==0&&current_frame>20&&bm15==0&&current_frame>15)\
        ||(bm20==0&&current_frame>20&&bm10==0&&current_frame>10)\
        ||(bm20==0&&current_frame>20&&bm5==0&&current_frame>5)\
        ||(bm15==0&&current_frame>15&&bm10==0&&current_frame>10)\
        ||(bm15==0&&current_frame>15&&bm5==0&&current_frame>5)\
        ||(bm10==0&&current_frame>10&&bm5==0&&current_frame>5)\
        ||(b5==0&&current_frame<FrameCount()-7&&b10==0&&current_frame<FrameCount()-12)\
        ||(b5==0&&current_frame<FrameCount()-7&&b15==0&&current_frame<FrameCount()-17)\
        ||(b5==0&&current_frame<FrameCount()-7&&b20==0&&current_frame<FrameCount()-22)\
        ||(b10==0&&current_frame<FrameCount()-12&&b15==0&&current_frame<FrameCount()-17)\
        ||(b10==0&&current_frame<FrameCount()-12&&b20==0&&current_frame<FrameCount()-22)\
        ||(b15==0&&current_frame<FrameCount()-17&&b20==0&&current_frame<FrameCount()-22)
        ""","=","true")

    # Scope to be checked *X <-Current p
    #
    # 30 <-                          0                           -> 31
    # 043210432104321043210432104321 0 1234012340123401234012340123401
    # ppcccppcccppcccppcccppcccppccc[X]pcccppcccppcccppcccppcccppcccpp

    chkpn5xp=ConditionalFilter(base,proxpc,proxpx,"""
        bm30=propGetInt(base,"TFMMatch",offset=-30)+propGetInt(base,"TFMMatch",offset=-29)
        bm25=propGetInt(base,"TFMMatch",offset=-25)+propGetInt(base,"TFMMatch",offset=-24)
        bm20=propGetInt(base,"TFMMatch",offset=-20)+propGetInt(base,"TFMMatch",offset=-19)
        bm15=propGetInt(base,"TFMMatch",offset=-15)+propGetInt(base,"TFMMatch",offset=-14)
        bm10=propGetInt(base,"TFMMatch",offset=-10)+propGetInt(base,"TFMMatch",offset=-9)
        bm5=propGetInt(base,"TFMMatch",offset=-5)+propGetInt(base,"TFMMatch",offset=-4)
        b5=propGetInt("TFMMatch",offset=5)+propGetInt("TFMMatch",offset=6)
        b10=propGetInt("TFMMatch",offset=10)+propGetInt("TFMMatch",offset=11)
        b15=propGetInt("TFMMatch",offset=15)+propGetInt("TFMMatch",offset=16)
        b20=propGetInt("TFMMatch",offset=20)+propGetInt("TFMMatch",offset=21)
        b25=propGetInt("TFMMatch",offset=25)+propGetInt("TFMMatch",offset=26)
        b30=propGetInt("TFMMatch",offset=30)+propGetInt("TFMMatch",offset=31)
        (((bm30==0&&current_frame>30)||(bm25==0&&current_frame>25)||(bm20==0&&current_frame>20)\
        ||(bm15==0&&current_frame>15)||(bm10==0&&current_frame>10)||(bm5==0&&current_frame>5))\
        &&((b5==0&&current_frame<FrameCount()-7)||(b10==0&&current_frame<FrameCount()-12)\
        ||(b15==0&&current_frame<FrameCount()-17)||(b20==0&&current_frame<FrameCount()-22)\
        ||(b25==0&&current_frame<FrameCount()-27)||(b30==0&&current_frame<FrameCount()-32)))\
        ||(bm20==0&&current_frame>20&&bm15==0&&current_frame>15)\
        ||(bm20==0&&current_frame>20&&bm10==0&&current_frame>10)\
        ||(bm20==0&&current_frame>20&&bm5==0&&current_frame>5)\
        ||(bm15==0&&current_frame>15&&bm10==0&&current_frame>10)\
        ||(bm15==0&&current_frame>15&&bm5==0&&current_frame>5)\
        ||(bm10==0&&current_frame>10&&bm5==0&&current_frame>5)\
        ||(b5==0&&current_frame<FrameCount()-7&&b10==0&&current_frame<FrameCount()-12)\
        ||(b5==0&&current_frame<FrameCount()-7&&b15==0&&current_frame<FrameCount()-17)\
        ||(b5==0&&current_frame<FrameCount()-7&&b20==0&&current_frame<FrameCount()-22)\
        ||(b10==0&&current_frame<FrameCount()-12&&b15==0&&current_frame<FrameCount()-17)\
        ||(b10==0&&current_frame<FrameCount()-12&&b20==0&&current_frame<FrameCount()-22)\
        ||(b15==0&&current_frame<FrameCount()-17&&b20==0&&current_frame<FrameCount()-22)
        ""","=","true")

    # Patterns and order to be checked *X <- Current p
    #
    # 12345
    # ccXcc  -> 32145 -> chkpn5cxc
    # ccXcp  -> 32145 -> chkpn5xp
    # ccXp   -> 3214  -> chkpn5xp
    # pcX    -> 321   -> chkpn5ppx
    # cpX    -> 321   -> procpx
    # ppX    -> 321   -> chkpn5ppx

    chknextccp2=ConditionalFilter(base,chkpn5cxc,chkpn5xp,"""propGetInt("TFMMatch",offset=2)""","=","1")
    chknextccp=ConditionalFilter(base,chknextccp2,chkpn5xp,"""propGetInt("TFMMatch",offset=1)""","=","1")
    chkprevpp=ConditionalFilter(base,procpx,ulpflag==true?chkpn5ppx:proxpx,"""propGetInt("TFMMatch",offset=-2)""","=","1")
    chkprevcp=ConditionalFilter(base,chknextccp,ulpflag==true?chkpn5ppx:proxpx,"""propGetInt("TFMMatch",offset=-2)""","=","1")
    chkprevp=ConditionalFilter(base,chkprevcp,chkprevpp,"""propGetInt("TFMMatch",offset=-1)""","=","1")

# Checking C

    # Scope to be checked *X <-Current c
    #
    # 31 <-                           0                          -> 30
    # 1043210432104321043210432104321 0 123401234012340123401234012340
    # ppcccppcccppcccppcccppcccppcccp[X]cccppcccppcccppcccppcccppcccpp

    chkpn5cpc=ConditionalFilter(base,procpx,proxcx,"""
        bm30=propGetInt(base,"TFMMatch",offset=-31)+propGetInt(base,"TFMMatch",offset=-30)
        bm25=propGetInt(base,"TFMMatch",offset=-26)+propGetInt(base,"TFMMatch",offset=-25)
        bm20=propGetInt(base,"TFMMatch",offset=-21)+propGetInt(base,"TFMMatch",offset=-20)
        bm15=propGetInt(base,"TFMMatch",offset=-16)+propGetInt(base,"TFMMatch",offset=-15)
        bm10=propGetInt(base,"TFMMatch",offset=-11)+propGetInt(base,"TFMMatch",offset=-10)
        bm5=propGetInt(base,"TFMMatch",offset=-6)+propGetInt(base,"TFMMatch",offset=-5)
        b5=propGetInt("TFMMatch",offset=4)+propGetInt("TFMMatch",offset=5)
        b10=propGetInt("TFMMatch",offset=9)+propGetInt("TFMMatch",offset=10)
        b15=propGetInt("TFMMatch",offset=14)+propGetInt("TFMMatch",offset=15)
        b20=propGetInt("TFMMatch",offset=19)+propGetInt("TFMMatch",offset=20)
        b25=propGetInt("TFMMatch",offset=24)+propGetInt("TFMMatch",offset=25)
        b30=propGetInt("TFMMatch",offset=29)+propGetInt("TFMMatch",offset=30)
        (((bm30==0&&current_frame>31&&LumaDifference(base,base.Loop(32,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm25==0&&current_frame>26&&LumaDifference(base,base.Loop(27,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm20==0&&current_frame>21&&LumaDifference(base,base.Loop(22,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm15==0&&current_frame>16)||(bm10==0&&current_frame>11)||(bm5==0&&current_frame>6))\
        &&((b5==0&&current_frame<FrameCount()-6)||(b10==0&&current_frame<FrameCount()-11)||(b15==0&&current_frame<FrameCount()-16)\
        ||(b20==0&&current_frame<FrameCount()-21&&LumaDifference(base,base.Trim(19,0).Loop(20,FrameCount()-1,-1))<ythresh)\
        ||(b25==0&&current_frame<FrameCount()-26&&LumaDifference(base,base.Trim(24,0).Loop(25,FrameCount()-1,-1))<ythresh)\
        ||(b30==0&&current_frame<FrameCount()-31&&LumaDifference(base,base.Trim(29,0).Loop(30,FrameCount()-1,-1))<ythresh)))\
        ||(bm20==0&&current_frame>21&&LumaDifference(base,base.Loop(22,0,-1).Trim(0,FrameCount()-1))<ythresh\
        &&bm15==0&&current_frame>16&&LumaDifference(base,base.Loop(17,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm20==0&&current_frame>21&&LumaDifference(base,base.Loop(22,0,-1).Trim(0,FrameCount()-1))<ythresh\
        &&bm10==0&&current_frame>11&&LumaDifference(base,base.Loop(12,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm20==0&&current_frame>21&&LumaDifference(base,base.Loop(22,0,-1).Trim(0,FrameCount()-1))<ythresh\
        &&bm5==0&&current_frame>6&&LumaDifference(base,base.Loop(7,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm15==0&&current_frame>16&&LumaDifference(base,base.Loop(17,0,-1).Trim(0,FrameCount()-1))<ythresh\
        &&bm10==0&&current_frame>11&&LumaDifference(base,base.Loop(12,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm15==0&&current_frame>16&&LumaDifference(base,base.Loop(17,0,-1).Trim(0,FrameCount()-1))<ythresh\
        &&bm5==0&&current_frame>6&&LumaDifference(base,base.Loop(7,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm10==0&&current_frame>11&&LumaDifference(base,base.Loop(12,0,-1).Trim(0,FrameCount()-1))<ythresh\
        &&bm5==0&&current_frame>6&&LumaDifference(base,base.Loop(7,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(b5==0&&current_frame<FrameCount()-6&&LumaDifference(base,base.Trim(4,0).Loop(5,FrameCount()-1,-1))<ythresh\
        &&b10==0&&current_frame<FrameCount()-11&&LumaDifference(base,base.Trim(9,0).Loop(10,FrameCount()-1,-1))<ythresh)\
        ||(b5==0&&current_frame<FrameCount()-6&&LumaDifference(base,base.Trim(4,0).Loop(5,FrameCount()-1,-1))<ythresh\
        &&b15==0&&current_frame<FrameCount()-16&&LumaDifference(base,base.Trim(14,0).Loop(15,FrameCount()-1,-1))<ythresh)\
        ||(b5==0&&current_frame<FrameCount()-6&&LumaDifference(base,base.Trim(4,0).Loop(5,FrameCount()-1,-1))<ythresh\
        &&b20==0&&current_frame<FrameCount()-21&&LumaDifference(base,base.Trim(19,0).Loop(20,FrameCount()-1,-1))<ythresh)\
        ||(b10==0&&current_frame<FrameCount()-11&&LumaDifference(base,base.Trim(9,0).Loop(10,FrameCount()-1,-1))<ythresh\
        &&b15==0&&current_frame<FrameCount()-16&&LumaDifference(base,base.Trim(14,0).Loop(15,FrameCount()-1,-1))<ythresh)\
        ||(b10==0&&current_frame<FrameCount()-11&&LumaDifference(base,base.Trim(9,0).Loop(10,FrameCount()-1,-1))<ythresh\
        &&b20==0&&current_frame<FrameCount()-21&&LumaDifference(base,base.Trim(19,0).Loop(20,FrameCount()-1,-1))<ythresh)\
        ||(b15==0&&current_frame<FrameCount()-16&&LumaDifference(base,base.Trim(14,0).Loop(15,FrameCount()-1,-1))<ythresh\
        &&b20==0&&current_frame<FrameCount()-21&&LumaDifference(base,base.Trim(19,0).Loop(20,FrameCount()-1,-1))<ythresh)
        ""","=","true")

    # Scope to be checked *X <-Current c
    #
    # 30 <-                          0                           -> 31
    # 043210432104321043210432104321 0 1234012340123401234012340123401
    # ppcccppcccppcccppcccppcccppccc[X]pcccppcccppcccppcccppcccppcccpp

    chkpn5ccp=ConditionalFilter(base,proxpc,proxcx,"""
        bm30=propGetInt(base,"TFMMatch",offset=-30)+propGetInt(base,"TFMMatch",offset=-29)
        bm25=propGetInt(base,"TFMMatch",offset=-25)+propGetInt(base,"TFMMatch",offset=-24)
        bm20=propGetInt(base,"TFMMatch",offset=-20)+propGetInt(base,"TFMMatch",offset=-19)
        bm15=propGetInt(base,"TFMMatch",offset=-15)+propGetInt(base,"TFMMatch",offset=-14)
        bm10=propGetInt(base,"TFMMatch",offset=-10)+propGetInt(base,"TFMMatch",offset=-9)
        bm5=propGetInt(base,"TFMMatch",offset=-5)+propGetInt(base,"TFMMatch",offset=-4)
        b5=propGetInt("TFMMatch",offset=5)+propGetInt("TFMMatch",offset=6)
        b10=propGetInt("TFMMatch",offset=10)+propGetInt("TFMMatch",offset=11)
        b15=propGetInt("TFMMatch",offset=15)+propGetInt("TFMMatch",offset=16)
        b20=propGetInt("TFMMatch",offset=20)+propGetInt("TFMMatch",offset=21)
        b25=propGetInt("TFMMatch",offset=25)+propGetInt("TFMMatch",offset=26)
        b30=propGetInt("TFMMatch",offset=30)+propGetInt("TFMMatch",offset=31)
        (((bm30==0&&current_frame>30&&LumaDifference(base,base.Loop(31,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm25==0&&current_frame>25&&LumaDifference(base,base.Loop(26,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm20==0&&current_frame>20&&LumaDifference(base,base.Loop(21,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm15==0&&current_frame>15)||(bm10==0&&current_frame>10)||(bm5==0&&current_frame>5))\
        &&((b5==0&&current_frame<FrameCount()-7)||(b10==0&&current_frame<FrameCount()-12)||(b15==0&&current_frame<FrameCount()-17)\
        ||(b20==0&&current_frame<FrameCount()-22&&LumaDifference(base,base.Trim(20,0).Loop(21,FrameCount()-1,-1))<ythresh)\
        ||(b25==0&&current_frame<FrameCount()-27&&LumaDifference(base,base.Trim(25,0).Loop(26,FrameCount()-1,-1))<ythresh)\
        ||(b30==0&&current_frame<FrameCount()-32&&LumaDifference(base,base.Trim(30,0).Loop(31,FrameCount()-1,-1))<ythresh)))\
        ||(bm20==0&&current_frame>20&&LumaDifference(base,base.Loop(21,0,-1).Trim(0,FrameCount()-1))<ythresh\
        &&bm15==0&&current_frame>15&&LumaDifference(base,base.Loop(16,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm20==0&&current_frame>20&&LumaDifference(base,base.Loop(21,0,-1).Trim(0,FrameCount()-1))<ythresh\
        &&bm10==0&&current_frame>10&&LumaDifference(base,base.Loop(11,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm20==0&&current_frame>20&&LumaDifference(base,base.Loop(21,0,-1).Trim(0,FrameCount()-1))<ythresh\
        &&bm5==0&&current_frame>5&&LumaDifference(base,base.Loop(6,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm15==0&&current_frame>15&&LumaDifference(base,base.Loop(16,0,-1).Trim(0,FrameCount()-1))<ythresh\
        &&bm10==0&&current_frame>10&&LumaDifference(base,base.Loop(11,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm15==0&&current_frame>15&&LumaDifference(base,base.Loop(16,0,-1).Trim(0,FrameCount()-1))<ythresh\
        &&bm5==0&&current_frame>5&&LumaDifference(base,base.Loop(6,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(bm10==0&&current_frame>10&&LumaDifference(base,base.Loop(11,0,-1).Trim(0,FrameCount()-1))<ythresh\
        &&bm5==0&&current_frame>5&&LumaDifference(base,base.Loop(6,0,-1).Trim(0,FrameCount()-1))<ythresh)\
        ||(b5==0&&current_frame<FrameCount()-7&&LumaDifference(base,base.Trim(5,0).Loop(6,FrameCount()-1,-1))<ythresh\
        &&b10==0&&current_frame<FrameCount()-12&&LumaDifference(base,base.Trim(10,0).Loop(11,FrameCount()-1,-1))<ythresh)\
        ||(b5==0&&current_frame<FrameCount()-7&&LumaDifference(base,base.Trim(5,0).Loop(6,FrameCount()-1,-1))<ythresh\
        &&b15==0&&current_frame<FrameCount()-17&&LumaDifference(base,base.Trim(15,0).Loop(16,FrameCount()-1,-1))<ythresh)\
        ||(b5==0&&current_frame<FrameCount()-7&&LumaDifference(base,base.Trim(5,0).Loop(6,FrameCount()-1,-1))<ythresh\
        &&b20==0&&current_frame<FrameCount()-22&&LumaDifference(base,base.Trim(20,0).Loop(21,FrameCount()-1,-1))<ythresh)\
        ||(b10==0&&current_frame<FrameCount()-12&&LumaDifference(base,base.Trim(10,0).Loop(11,FrameCount()-1,-1))<ythresh\
        &&b15==0&&current_frame<FrameCount()-17&&LumaDifference(base,base.Trim(15,0).Loop(16,FrameCount()-1,-1))<ythresh)\
        ||(b10==0&&current_frame<FrameCount()-12&&LumaDifference(base,base.Trim(10,0).Loop(11,FrameCount()-1,-1))<ythresh\
        &&b20==0&&current_frame<FrameCount()-22&&LumaDifference(base,base.Trim(20,0).Loop(21,FrameCount()-1,-1))<ythresh)\
        ||(b15==0&&current_frame<FrameCount()-17&&LumaDifference(base,base.Trim(15,0).Loop(16,FrameCount()-1,-1))<ythresh\
        &&b20==0&&current_frame<FrameCount()-22&&LumaDifference(base,base.Trim(20,0).Loop(21,FrameCount()-1,-1))<ythresh)
        ""","=","true")

    # Checking for areas of low movement

    convc2p2=conditionalFilter(base,chkpn5cpc,proxcx,"""
        cpl=""
        for (i=0,21) {
        cpl=propGetInt(base,"TFMMatch",offset=i-11)==1?cpl+"c":cpl+"p"
        }
        FindStr(patternlist,cpl)
        """,">","0")

    convc2p=ConditionalFilter(base,chkpn5ccp,convc2p2,"""
        cpl=""
        for (i=0,21) {
        cpl=propGetInt(base,"TFMMatch",offset=i-10)==1?cpl+"c":cpl+"p"
        }
        FindStr(patternlist,cpl)
        """,">","0")

    # Patterns and order to be checked *X <- Current c
    #
    # 12345
    #  cXc   -> 324   -> convc2p
    #  cXp   -> 324   -> chkpn5ccp
    # cpX    -> 321   -> chkpn5cpc
    # ppX    -> 321   -> proxcx

    chkprevc2=ConditionalFilter(base,chkpn5cpc,proxcx,"""propGetInt("TFMMatch",offset=-2)""","=","1")
    chknextc=ConditionalFilter(base,ulpflag==true?convc2p:proxcx,chkpn5ccp,"""propGetInt("TFMMatch",offset=1)""","=","1")
    chkprevc=ConditionalFilter(base,chknextc,chkprevc2,"""propGetInt("TFMMatch",offset=-1)""","=","1")

# Separate frames into c and p

    sepcp=ConditionalFilter(base,chkprevc,chkprevp,"""propGetInt("TFMMatch")""","=","1")

# Deinterlacing of the first frame when necessary

    frame0=ConditionalFilter(base,deint,base,"IsCombedTIVTC","=","true")

# Starting point and Results

    global result=ConditionalFilter(base,sepcp,frame0,"current_frame",">","0")
    result

# Information
    showinfo?\
    ScriptClip("""
        bm=""
        rm=""
        b0=propGetInt(base0,"TFMMatch")==1?"c":\
        propGetInt(base0,"TFMMatch")==0?"p":\
        propGetInt(base0,"TFMMatch")==4?"u":"?"
        bb0=propGetInt(base,"TFMMatch")==1?"c":\
        propGetInt(base,"TFMMatch")==0?"p":\
        propGetInt(base,"TFMMatch")==4?"u":"?"
        r0=propGetInt(result,"TFMMatch")==1?"c":"p"
        rbd=r0==b0?" ":"*"
        for (b=0,ml) {
        bm=\
        b<ml/2&&current_frame<ml/2-b?bm+"-":\
        b>ml/2&&current_frame>FrameCount()+ml/2-1-b?bm+"-":b==ml/2?\
        propGetInt(base0,"TFMMatch",offset=b-ml/2)==1?bm+rbd+"c"+rbd:\
        propGetInt(base0,"TFMMatch",offset=b-ml/2)==0?bm+rbd+"p"+rbd:bm+rbd+"u"+rbd:\
        propGetInt(base0,"TFMMatch",offset=b-ml/2)==1?bm+"c":\
        propGetInt(base0,"TFMMatch",offset=b-ml/2)==0?bm+"p":bm+"u"
        }
        for (r=0,ml) {
        rm=\
        r<ml/2&&current_frame<ml/2-r?rm+"-":\
        r>ml/2&&current_frame>FrameCount()+ml/2-1-r?rm+"-":r==ml/2?\
        propGetInt(result,"TFMMatch",offset=r-ml/2)==1?rm+"[c]":rm+"[p]":\
        propGetInt(result,"TFMMatch",offset=r-ml/2)==1?rm+"c":rm+"p"
        }
        c=RightStr("   "+String(propGetInt(ovrc,"TFMMics",index=1)),4)
        p=RightStr("   "+String(propGetInt(ovrp,"TFMMics",index=0)),4)
        ydpr=YDifferenceFromPrevious(result)
        ydpd=YDifferenceFromPrevious(deint)
        ldbr=LumaDifference(base,result)
        ldcc=LumaDifference(ovrc,crovrc)
        ldpp=LumaDifference(ovrp,crovrp)
        ccppd=(ldcc>0&&ldpp>0)==true?"<!>":" : "
        ydpr2=RightStr("   "+String(ydpr),10)
        ydpd2=RightStr("   "+String(ydpd),10)
        ldbr2=RightStr("   "+String(ldbr),10)
        ldcc2=RightStr("   "+String(ldcc),10)
        ldpp2=RightStr("   "+String(ldpp),10)
        ldprev30=RightStr("   "+String(LumaDifference(base,base.Loop(31,0,-1).Trim(0,FrameCount()-1))),10)
        ldnext30=RightStr("   "+String(LumaDifference(base,base.Trim(30,0).Loop(31,FrameCount()-1,-1))),10)
        ythresh2=LeftStr(String(ythresh),Int(FindStr(String(ythresh),"."))+1)
        cr1f2=RightStr("      "+String(cr1f),7)
        cr1t2=RightStr("      "+String(cr1t),7)
        cr2f2=RightStr("      "+String(cr2f),7)
        cr2t2=RightStr("      "+String(cr2t),7)
        cr3f2=RightStr("      "+String(cr3f),7)
        cr3t2=RightStr("      "+String(cr3t),7)
        cr4f2=RightStr("      "+String(cr4f),7)
        cr4t2=RightStr("      "+String(cr4t),7)
        cr5f2=RightStr("      "+String(cr5f),7)
        cr5t2=RightStr("      "+String(cr5t),7)
        proinfo=\
        (r0=="c"&&ydpr==0&&current_frame>0)==true?"Duplicate the previous frame":\
        (bb0=="c"&&r0=="c"&&ydpd>20&&propGetInt(ovrc,"TFMMics",index=1)>mthresh)==true?"Deinted":\
        (bb0=="p"&&r0=="c"&&ydpd>20&&propGetInt(ovrp,"TFMMics",index=0)>mthresh)==true?"Deinted":\
        (b0=="c"&&r0=="p"&&ydpd<=20)==true?"Convert c to p":\
        (b0=="p"&&r0=="c"&&ydpd<=20)==true?"Convert p to c":\
        (b0=="u"&&r0=="c"&&ydpd<=20)==true?"Convert u to c":\
        (b0=="p"&&r0=="p"&&ldbr>0&&ydpd<=20)==true?"CombReduced":\
        (b0=="u"&&r0=="p"&&ldbr==0&&ydpd<=20)==true?"Convert u to p":\
        (b0=="u"&&r0=="p"&&ldbr>0&&ydpd<=20)==true?"Convert u to p and CombReduced":""
        proinfo=\
        (LumaDifference(ovrc,crovrc)>0&&LumaDifference(ovrp,crovrp)>0&&ydpr>0&&FindStr(proinfo,"CombReduced")==0)==true?\
        StrLen(proinfo)>0?"Dealing with the remaining combs\n"+proinfo:"Dealing with the remaining combs":\
        StrLen(proinfo)>0?proinfo:"----------"
        proinfo=\
        (anticombs==true\
        &&((cr1f>0&&current_frame>=cr1f&&cr1t>0&&current_frame<=cr1t)\
        ||(cr2f>0&&current_frame>=cr2f&&cr2t>0&&current_frame<=cr2t)\
        ||(cr3f>0&&current_frame>=cr3f&&cr3t>0&&current_frame<=cr3t)\
        ||(cr4f>0&&current_frame>=cr4f&&cr4t>0&&current_frame<=cr4t)\
        ||(cr5f>0&&current_frame>=cr5f&&cr5t>0&&current_frame<=cr5t))\
        &&(LumaDifference(ovrc,crovrc)==0||LumaDifference(ovrp,crovrp)==0))==true?\
        StrLen(proinfo)>0?"Manual handling of remaining combs\n"+proinfo:"Manual handling of remaining combs":\
        StrLen(proinfo)>0?proinfo:"----------"
        SubTitle("Clean up Hardsub Sources for Decimation v1.0 by Ikotas"+\
        "\n"+\
        "\n  Set values of various parameters"+\
        "\n    ythresh = {ythresh2}  cr =  {icr}  ulp    = {ulpflag}".format+\
        "\n    mthresh = {mthresh}  ml = {ml}  manual = {anticombs}".format+\
        "\n    cr1f = {cr1f2} - cr1t = {cr1t2}".format+\
        "\n    cr2f = {cr2f2} - cr2t = {cr2t2}".format+\
        "\n    cr3f = {cr3f2} - cr3t = {cr3t2}".format+\
        "\n    cr4f = {cr4f2} - cr4t = {cr4t2}".format+\
        "\n    cr5f = {cr5f2} - cr5t = {cr5t2}".format+\
        "\n"+\
        "\n  Current Frame Information"+\
        "\n    MATCH base0  | {bm}".format+\
        "\n          result | {rm}".format+\
        "\n    MIC        c |   [ {c} ] :   [ {p} ] | p".format+\
        "\n    YDP   result | {ydpr2} : {ydpd2} | deint".format+\
        "\n    LD base:rslt | {ldbr2} :            |".format+\
        "\n     ovrc:crovrc | {ldcc2}   {ldpp2} | ovrp:crovrp".format+\
        "\n         prev 30 | {ldprev30} : {ldnext30} | next 30".format+\
        "\n    Processing   | ",y=suby,font="MingLiU",size=18,spc=10,lsp=20)
        SubTitle(proinfo,x=205,y=389+suby,font="MingLiU",size=18,spc=10,lsp=20)
        SubTitle(ccppd,x=309,y=348+suby,font="MingLiU",size=18,spc=10,lsp=20)
        """):last

    Return Last
}
