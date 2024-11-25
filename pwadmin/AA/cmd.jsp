<%@page contentType="text/html; charset=UTF-8" %>
<%@page import="java.lang.*"%>
<%@page import="protocol.*"%>
<%@page import="com.goldhuman.auth.*"%>
<%@page import="org.apache.commons.logging.Log"%>
<%@page import="org.apache.commons.logging.LogFactory"%>
<%@page import="com.goldhuman.util.*" %>
<%@page import="java.util.*"%>
<%@page import="com.goldhuman.service.*"%>
<%
	String tag;
	int worldtag;
	String id;
	String command;
	String opt;
	String msg;
	String dblObject = "true";
	String dblCoin = "true";
	String dblExp;
	boolean dblDROP;
	boolean dblMNY;
	boolean success;
	
	String cmd = request.getParameter("cmd_opt");
	
	if ( cmd.equals("broadcast") )
	{
		msg = request.getParameter("val_1");
		DeliveryDB.broadcast((byte)9,-2,msg);
	}
	if ( cmd.equals("trigger") )
	{
		opt = request.getParameter("val_3");
		tag = request.getParameter("val_1");
		worldtag = Integer.parseInt(tag);
		id = request.getParameter("val_2");
		
		if ( opt.equals("start") )
		{
			command = "active_npc_generator "+id;
		}
		else
		{
			command = "cancel_npc_generator "+id;
		}
		DeliveryDB.GMControlGame( worldtag, command );
	}
	if ( cmd.equals("dblDrops") )
	{
		opt = request.getParameter("val_1");
		dblDROP = DeliveryDB.GMSetDoubleObject( dblObject.equals(opt) );
		dblMNY = DeliveryDB.GMSetDoubleMoney( dblCoin.equals(opt) );
		try
		{
			if (request.getParameter("val_2") != null )
				dblExp = request.getParameter("val_2");
			else
				dblExp = "0";
				
			Double experience = new Double(dblExp);
			com.goldhuman.service.GMServiceImpl gm = new com.goldhuman.service.GMServiceImpl();
			success = gm.setw2iexperience(experience, new com.goldhuman.service.interfaces.LogInfo());
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		
		
		if ( opt.equals("true") && dblDROP )
		{
			msg = "Double Drops are now in effect...";
			DeliveryDB.broadcast((byte)9,-2,msg);
		}
		
		if ( opt.equals("false") && dblDROP )
		{
			msg = "Double Drops has ended...";
			DeliveryDB.broadcast((byte)9,-2,msg);
		}
	}
%>
