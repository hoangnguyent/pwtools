<%@page import="java.util.*"%>
<%@page import="protocol.*"%>
<%@page import="com.goldhuman.Common.Octets"%>
<%@include file="../../WEB-INF/.pwadminconf.jsp"%>

<%!
	byte[] hextoByteArray(String x)
  	{
    		if (x.length() < 2)
		{
      			return new byte[0];
		}
    		if (x.length() % 2 != 0)
		{
      			System.err.println("hextoByteArray error! hex size=" + Integer.toString(x.length()));
    		}
    		byte[] rb = new byte[x.length() / 2];
   		for (int i = 0; i < rb.length; ++i)
    		{
      			rb[i] = 0;

      			int n = x.charAt(i + i);
      			if ((n >= 48) && (n <= 57))
        			n -= 48;
      			else
				if ((n >= 97) && (n <= 102))
        				n = n - 97 + 10;
      					rb[i] = (byte)(rb[i] | n << 4 & 0xF0);

      					n = x.charAt(i + i + 1);
      					if ((n >= 48) && (n <= 57))
        					n -= 48;
      					else
					if ((n >= 97) && (n <= 102))
        					n = n - 97 + 10;
      				rb[i] = (byte)(rb[i] | n & 0xF);
    	}
    	return rb;
  }
%>

<%
	String message = "<br>";
	boolean allowed = false;

	if(request.getSession().getAttribute("ssid") == null)
	{
		message = "<font color=\"#ee0000\"><b>Login to use Send Mail...</b></font>";
	}
	else
	{
		allowed = true;
	}
%>

<%
	if(allowed && request.getParameter("process") != null && request.getParameter("process").compareTo("mail") == 0)
	{
		if(request.getParameter("roleid") != "" && request.getParameter("title") != "" && request.getParameter("content") != "" && request.getParameter("coins") != "" && request.getParameter("itemid") != "")
		{
			int roleid = Integer.parseInt(request.getParameter("roleid"));
			String title = request.getParameter("title");
			String content = request.getParameter("content");
			int coins = Integer.parseInt(request.getParameter("coins"));

			int itemnumber = Integer.parseInt(request.getParameter("itemid"));
			GRoleInventory gri = new GRoleInventory();

			if(itemnumber > 0)
			{
				gri.id = Integer.parseInt(request.getParameter("itemid"));
				gri.guid1 = 0;
				gri.guid2 = 0;
				gri.mask = Integer.parseInt(request.getParameter("itemmask"));
				gri.proctype = Integer.parseInt(request.getParameter("itemproc"));
				gri.pos = 0;
				gri.count = Integer.parseInt(request.getParameter("itemstacked"));
				gri.max_count = Integer.parseInt(request.getParameter("itemstackmax"));
				gri.expire_date = Integer.parseInt(request.getParameter("itemexpire"));
				gri.data = new Octets(hextoByteArray(request.getParameter("itemhex")));
			}

			if(protocol.DeliveryDB.SysSendMail(roleid, title, content, gri, coins))
			{
				message = "<font color=\"#00cc00\"><b>Mail Send</b></font>";
			}
			else
			{
				message = "<font color=\"#ee0000\"><b>Sending Mail Failed</b></font>";
			}
		}
		else
		{
			message = "<font color=\"#ee0000\"><b>Enter Valid Values</b></font>";
		}
	}
%>

<html>

<head>
	<link rel="shortcut icon" href="../../include/fav.ico">
	<link rel="stylesheet" type="text/css" href="../../include/style.css">
</head>

<body>

<form action="manual.jsp?process=mail" method="post">

<table align="center" width="480" cellpadding="2" cellspacing="0" style="border: 1px solid #cccccc;">
	<tr>
		<th height="1" colspan="2" style="padding: 5;">
			<b>SEND MAIL</b>&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp(<a href="./index.jsp">Back</a>)
		</th>
	</tr>
	<tr bgcolor="#f0f0f0">
		<td colspan="2" align="center" height="1">
			<% out.print(message); %>
		</td>
	</tr>
	<tr>
		<td height="1">
			Role ID:
		</td>
		<td height="1">
			<input type="text" name="roleid" style="width: 100%; text-align: left;"></input>
		</td>
	</tr>
	<tr>
		<td height="1">
			Title:
		</td>
		<td height="1">
			<input type="text" name="title" style="width: 100%; text-align: left;"></input>
		</td>
	</tr>
	<tr>
		<td height="1" valign="top">
			Content:
		</td>
		<td height="1">
			<textarea name="content" rows="5" style="width: 100%; text-align: left;"></textarea>
		</td>
	</tr>
	<tr>
		<td height="1">
			Coins:
		</td>
		<td height="1">
			<input type="text" name="coins" value="0" style="width: 100%; text-align: left;"></input>
		</td>
	</tr>
<tr><td><br></td></tr>
	<tr>
		<td height="1">
			Item ID:
		</td>
		<td height="1">
			<input type="text" name="itemid" value="0" style="width: 100%; text-align: left;"></input>
		</td>
	</tr>
	<tr>
		<td height="1">
			Item Hex:
		</td>
		<td height="1">
			<input type="text" name="itemhex" value="" style="width: 100%; text-align: left;"></input>
		</td>
	</tr>	<tr>
		<td height="1">
			Item Mask:
		</td>
		<td height="1">
			<input type="text" name="itemmask" value="0" style="width: 100%; text-align: left;"></input>
		</td>
	</tr>	<tr>
		<td height="1">
			Item Proctype:
		</td>
		<td height="1">
			<input type="text" name="itemproc" value="0" style="width: 100%; text-align: left;"></input>
		</td>
	</tr>	<tr>
		<td height="1">
			Item Stack:
		</td>
		<td height="1">
			<input type="text" name="itemstacked" value="0" style="width: 100%; text-align: left;"></input>
		</td>
	</tr>	<tr>
		<td height="1">
			Item Max Stack:
		</td>
		<td height="1">
			<input type="text" name="itemstackmax" value="0" style="width: 100%; text-align: left;"></input>
		</td>
	</tr>	<tr>
		<td height="1">
			Item Expire Date:
		</td>
		<td height="1">
			<input type="text" name="itemexpire" value="0" style="width: 100%; text-align: left;"></input>
		</td>
	</tr>
	<tr bgcolor="#f0f0f0">
		<td colspan="2" align="center" height="1">
			<input type="image" src="../../include/btn_submit.jpg" style="border: 0;"></input>
		</td>
	</tr>
</table>

</form>

 <center>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~<br>
 ITEM MASK:<br>
 <br>
 0 = Not To Be Equipped<br>
 1 = Weapon<br>
 2= Helmet<br>
 4 = Necklace<br>
 8 = Robe<br>
 16 = Chest Armor<br>
 32 = Belt<br>
 64 = Leg Armor<br>
 128 = Foot Armor<br>
 256 = Arm Armor<br>
 1536 = Ring<br>
 1536 = Ring<br>
 2048 = Ammunition<br>
 4096 = Flyer Mount<br>
 8192 = Chest Clothing/Fashion<br>
 16384 = Leg Clothing/Fashion<br>
 32768 = Foot Clothing/Fashion<br>
 65536 = Arm Clothing/Fashion<br>
 131072 = Hierogram<br>
 262144 = Heaven Book/Tome<br>
 524288 = Chat Smiley<br>
 1048576 = HP Charm<br>
 2097152 = MP Charm<br>
 <br>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~<br>
 ITEM PROCTYPE:<br>
 <br>
 32791 = SoulBound<br>
 64 = Bind on equipping<br>
 55 = (? CHRONO KEY){cannot drop , cannot trade , cannot sell to npc}<br>
 19 = (? FB Tabs){cannot drop , cannot trade}<br>
 8 = (? Clothing/Binding Charm){}<br>
 1 = (? Revival Scroll){}<br>
 <br>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~<br>
 Expire Date:<br>
 value is equal to the unix clock time you want the item to expire<br>
 ie...<br>
 to get current unix time type "date +%s"<br>
 (or... (it) is the time in seconds that have elapsed since 01-01-1970 00:00:00 UTC)<br>
 add the amount of time you want the item to last, in seconds, to current unix time<br>
 (ie. 7 days = 604800 seconds, so you would add 604800 to current time)<br>
 <br>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~<br>
 <br>
</center>

</body>

</html>