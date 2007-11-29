/*
 * Automatically generated by jrpcgen 1.0.7 on 11/29/07 3:13 PM
 * jrpcgen is part of the "Remote Tea" ONC/RPC package for Java
 * See http://remotetea.sourceforge.net for details
 */
package com.parc.ccn.network.rpc;
import org.acplt.oncrpc.*;
import java.io.IOException;

import java.net.InetAddress;

/**
 * The class <code>Repo2TransportClient</code> implements the client stub proxy
 * for the REPOTOTRANSPORTPROG remote program. It provides method stubs
 * which, when called, in turn call the appropriate remote method (procedure).
 */
public class Repo2TransportClient extends OncRpcClientStub {

    /**
     * Constructs a <code>Repo2TransportClient</code> client stub proxy object
     * from which the REPOTOTRANSPORTPROG remote program can be accessed.
     * @param host Internet address of host where to contact the remote program.
     * @param protocol {@link org.acplt.oncrpc.OncRpcProtocols Protocol} to be
     *   used for ONC/RPC calls.
     * @throws OncRpcException if an ONC/RPC error occurs.
     * @throws IOException if an I/O error occurs.
     */
    public Repo2TransportClient(InetAddress host, int protocol)
           throws OncRpcException, IOException {
        super(host, Repo2Transport.REPOTOTRANSPORTPROG, 1, 0, protocol);
    }

    /**
     * Constructs a <code>Repo2TransportClient</code> client stub proxy object
     * from which the REPOTOTRANSPORTPROG remote program can be accessed.
     * @param host Internet address of host where to contact the remote program.
     * @param port Port number at host where the remote program can be reached.
     * @param protocol {@link org.acplt.oncrpc.OncRpcProtocols Protocol} to be
     *   used for ONC/RPC calls.
     * @throws OncRpcException if an ONC/RPC error occurs.
     * @throws IOException if an I/O error occurs.
     */
    public Repo2TransportClient(InetAddress host, int port, int protocol)
           throws OncRpcException, IOException {
        super(host, Repo2Transport.REPOTOTRANSPORTPROG, 1, port, protocol);
    }

    /**
     * Constructs a <code>Repo2TransportClient</code> client stub proxy object
     * from which the REPOTOTRANSPORTPROG remote program can be accessed.
     * @param client ONC/RPC client connection object implementing a particular
     *   protocol.
     * @throws OncRpcException if an ONC/RPC error occurs.
     * @throws IOException if an I/O error occurs.
     */
    public Repo2TransportClient(OncRpcClient client)
           throws OncRpcException, IOException {
        super(client);
    }

    /**
     * Constructs a <code>Repo2TransportClient</code> client stub proxy object
     * from which the REPOTOTRANSPORTPROG remote program can be accessed.
     * @param host Internet address of host where to contact the remote program.
     * @param program Remote program number.
     * @param version Remote program version number.
     * @param protocol {@link org.acplt.oncrpc.OncRpcProtocols Protocol} to be
     *   used for ONC/RPC calls.
     * @throws OncRpcException if an ONC/RPC error occurs.
     * @throws IOException if an I/O error occurs.
     */
    public Repo2TransportClient(InetAddress host, int program, int version, int protocol)
           throws OncRpcException, IOException {
        super(host, program, version, 0, protocol);
    }

    /**
     * Constructs a <code>Repo2TransportClient</code> client stub proxy object
     * from which the REPOTOTRANSPORTPROG remote program can be accessed.
     * @param host Internet address of host where to contact the remote program.
     * @param program Remote program number.
     * @param version Remote program version number.
     * @param port Port number at host where the remote program can be reached.
     * @param protocol {@link org.acplt.oncrpc.OncRpcProtocols Protocol} to be
     *   used for ONC/RPC calls.
     * @throws OncRpcException if an ONC/RPC error occurs.
     * @throws IOException if an I/O error occurs.
     */
    public Repo2TransportClient(InetAddress host, int program, int version, int port, int protocol)
           throws OncRpcException, IOException {
        super(host, program, version, port, protocol);
    }

    /**
     * Call remote procedure RegisterInterest_1.
     * @param arg1 parameter (of type Name) to the remote procedure call.
     * @return Result from remote procedure call (of type int).
     * @throws OncRpcException if an ONC/RPC error occurs.
     * @throws IOException if an I/O error occurs.
     */
    public int RegisterInterest_1(Name arg1)
           throws OncRpcException, IOException {
        XdrInt result$ = new XdrInt();
        client.call(Repo2Transport.RegisterInterest_1, Repo2Transport.REPOTOTRANSPORTVERSION, arg1, result$);
        return result$.intValue();
    }

    /**
     * Call remote procedure CancelInterest_1.
     * @param arg1 parameter (of type Name) to the remote procedure call.
     * @return Result from remote procedure call (of type int).
     * @throws OncRpcException if an ONC/RPC error occurs.
     * @throws IOException if an I/O error occurs.
     */
    public int CancelInterest_1(Name arg1)
           throws OncRpcException, IOException {
        XdrInt result$ = new XdrInt();
        client.call(Repo2Transport.CancelInterest_1, Repo2Transport.REPOTOTRANSPORTVERSION, arg1, result$);
        return result$.intValue();
    }

}
// End of Repo2TransportClient.java
